import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/round.dart';
import '../services/round_service.dart';
import '../theme/app_theme.dart';
import '../widgets/weather_widgets.dart';

class RoundDetailScreen extends StatefulWidget {
  final Round round;
  const RoundDetailScreen({super.key, required this.round});

  @override
  State<RoundDetailScreen> createState() => _RoundDetailScreenState();
}

class _RoundDetailScreenState extends State<RoundDetailScreen> {
  final _screenshotController = ScreenshotController();
  bool _sharing = false;

  double get _sw => MediaQuery.of(context).size.width;
  double get _sh => MediaQuery.of(context).size.height;

  // ── Score colour coding ───────────────────────────────────────────────────
  Color _scoreColor(int diff) {
    if (diff <= -2) return const Color(0xFFFFD700);
    if (diff == -1) return const Color(0xFF4CAF82);
    if (diff == 0)  return const Color(0xFFFFB74D);
    if (diff == 1)  return const Color(0xFFFFB74D);
    return const Color(0xFFE53935);
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  // ── Share as PNG ──────────────────────────────────────────────────────────
  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final bytes = await _screenshotController.capture(pixelRatio: 2.0);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/scorecard_${widget.round.id}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${widget.round.courseName} — ${widget.round.scoreDiffLabel} (${widget.round.totalScore})',
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> _delete() async {
    final c = AppColors.of(context);
    final sw = _sw;
    final sh = _sh;
    final body = (sw * 0.036).clamp(13.0, 16.0);
    const red = Color(0xFFFF6B6B);

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: c.sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: c.cardBorder)),
        ),
        padding: EdgeInsets.fromLTRB(
          (sw * 0.065).clamp(22.0, 32.0),
          20,
          (sw * 0.065).clamp(22.0, 32.0),
          (sh * 0.05).clamp(24.0, 40.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: c.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: sh * 0.032),
            Container(
              width: 60, height: 60,
              decoration: ShapeDecoration(
                color: red.withValues(alpha: 0.12),
                shape: SuperellipseShape(
                  borderRadius: BorderRadius.circular(36),
                  side: BorderSide(color: red.withValues(alpha: 0.3)),
                ),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: red, size: 26),
            ),
            SizedBox(height: sh * 0.020),
            Text('Delete Round?',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: c.primaryText,
                    fontSize: (sw * 0.052).clamp(18.0, 22.0),
                    fontWeight: FontWeight.w700)),
            SizedBox(height: sh * 0.008),
            Text(
              'This will permanently remove your round at ${widget.round.courseName}.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.secondaryText, fontSize: body * 0.9),
            ),
            SizedBox(height: sh * 0.036),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: (sh * 0.065).clamp(48.0, 58.0),
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetCtx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.primaryText,
                        side: BorderSide(color: c.cardBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Cancel',
                          style: TextStyle(
                              fontSize: body, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: (sh * 0.065).clamp(48.0, 58.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(sheetCtx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Delete',
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: body,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirm == true && mounted) {
      await RoundService.deleteRound(widget.round.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final round = widget.round;
    final body = (_sw * 0.036).clamp(13.0, 16.0);
    final label = (_sw * 0.030).clamp(11.0, 13.0);

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: c.primaryText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          round.courseName,
          style: TextStyle(fontFamily: 'Nunito',
              color: c.primaryText,
              fontSize: body * 1.1,
              fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_sharing)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: c.accent, strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.ios_share_rounded, color: c.accent, size: 22),
              onPressed: _share,
              tooltip: 'Share scorecard',
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFFF6B6B), size: 22),
            onPressed: _delete,
            tooltip: 'Delete round',
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            (_sw * 0.055).clamp(18.0, 28.0),
            _sh * 0.012,
            (_sw * 0.055).clamp(18.0, 28.0),
            _sh * 0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary header card ────────────────────────────────────────
            Container(
              decoration: ShapeDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A3A08), Color(0xFF3D6E14), Color(0xFF5A9E1F)],
                  stops: [0.0, 0.55, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: SuperellipseShape(
                  borderRadius: BorderRadius.circular(48),
                ),
                shadows: [
                  BoxShadow(
                    color: const Color(0xFF5A9E1F).withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: EdgeInsets.all((_sw * 0.055).clamp(18.0, 24.0)),
              child: Row(
                children: [
                  // Big score
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${round.totalScore}',
                        style: TextStyle(fontFamily: 'Nunito',
                          color: Colors.white,
                          fontSize: (_sw * 0.16).clamp(52.0, 68.0),
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        round.scoreDiffLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: body,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (round.courseLocation.isNotEmpty)
                          Row(children: [
                            Icon(Icons.location_on_rounded,
                                color: Colors.white.withValues(alpha: 0.6),
                                size: label),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(round.courseLocation,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: label,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.calendar_today_rounded,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: label),
                          const SizedBox(width: 4),
                          Text(_formatDate(round.startedAt),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: label,
                              )),
                        ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.sports_golf_rounded,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: label),
                          const SizedBox(width: 4),
                          Text('${round.totalHoles} holes',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: label,
                              )),
                          if (round.courseRating != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'CR ${round.courseRating!.toStringAsFixed(1)} / S ${round.slopeRating ?? "-"}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: label * 0.88,
                              ),
                            ),
                          ],
                        ]),
                        if (round.weather != null) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.thermostat_rounded,
                                color: Colors.white.withValues(alpha: 0.6),
                                size: label),
                            const SizedBox(width: 4),
                            Text(
                              '${round.weather!.tempF.round()}°F · ${round.weather!.condition} · ${round.weather!.windMph.round()} mph ${round.weather!.windDir}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: label * 0.9,
                              ),
                            ),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: _sh * 0.016),

            // ── Mini stats row ─────────────────────────────────────────────
            Container(
              decoration: ShapeDecoration(
                color: c.cardBg,
                shape: SuperellipseShape(
                  borderRadius: BorderRadius.circular(40),
                  side: BorderSide(color: c.cardBorder),
                ),
                shadows: c.cardShadow,
              ),
              padding: EdgeInsets.symmetric(
                  vertical: _sh * 0.016,
                  horizontal: (_sw * 0.04).clamp(12.0, 18.0)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statChip(c, '${round.birdies}', 'Birdies',
                      const Color(0xFF4CAF82), label),
                  _statChip(c, '${round.pars}', 'Pars',
                      const Color(0xFFFFB74D), label),
                  _statChip(c, '${round.bogeys}', 'Bogeys',
                      const Color(0xFFE53935), label),
                  _statChip(c, '${round.totalPutts}', 'Putts',
                      c.secondaryText, label),
                  _statChip(
                      c,
                      round.fairwaysHitPct > 0
                          ? '${round.fairwaysHitPct.toStringAsFixed(0)}%'
                          : '-',
                      'FIR',
                      c.secondaryText,
                      label),
                ],
              ),
            ),

            SizedBox(height: _sh * 0.022),

            // ── Weather conditions ─────────────────────────────────────────
            if (round.weather != null) ...[
              RoundConditionsCard(existingWeather: round.weather),
              SizedBox(height: _sh * 0.022),
            ],

            // ── Hole-by-hole scorecard (screenshotted) ─────────────────────
            Text(
              'Scorecard',
              style: TextStyle(fontFamily: 'Nunito',
                color: c.primaryText,
                fontSize: body * 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: _sh * 0.012),

            Screenshot(
              controller: _screenshotController,
              child: _buildScorecardTable(c, round, body, label),
            ),
          ],
        ),
      ),
    );
  }

  // ── Screenshotted scorecard table ─────────────────────────────────────────
  Widget _buildScorecardTable(
      AppColors c, Round round, double body, double label) {
    final hasClub = round.scores.any((h) => h.club != null);

    return Container(
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(40),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      child: Column(
        children: [
          // Header row
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _headerFlex(1, 'Hole', label, center: true),
                _headerFlex(1, 'Par', label, center: true),
                _headerFlex(1, 'Score', label, center: true),
                _headerFlex(1, 'Putts', label, center: true),
                _headerFlex(1, 'FIR', label, center: true),
                _headerFlex(1, 'GIR', label, center: true),
                if (hasClub) _headerFlex(2, 'Club', label),
              ],
            ),
          ),
          // Hole rows
          ...round.scores.map((h) {
            final diff = h.score - h.par;
            final color = _scoreColor(diff);
            final isLast = h.hole == round.scores.last.hole;
            return Container(
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(bottom: BorderSide(color: c.divider, width: 0.5)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                children: [
                  _dataFlex(1, '${h.hole}', label, c.secondaryText, center: true),
                  _dataFlex(1, '${h.par}', label, c.tertiaryText, center: true),
                  // Score chip
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: color.withValues(alpha: 0.4)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${h.score}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: color,
                            fontSize: label,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _dataFlex(1, '${h.putts}', label, c.secondaryText, center: true),
                  Expanded(
                    child: Center(
                      child: Icon(
                        h.par >= 4
                            ? (h.fairwayHit ? Icons.check_rounded : Icons.close_rounded)
                            : Icons.remove_rounded,
                        color: h.par >= 4
                            ? (h.fairwayHit ? const Color(0xFF34D399) : const Color(0xFFFF6B6B))
                            : c.tertiaryText,
                        size: label * 1.1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Icon(
                        h.gir ? Icons.check_rounded : Icons.close_rounded,
                        color: h.gir ? const Color(0xFF34D399) : const Color(0xFFFF6B6B),
                        size: label * 1.1,
                      ),
                    ),
                  ),
                  if (hasClub)
                    Expanded(
                      flex: 2,
                      child: Text(
                        h.club ?? '—',
                        style: TextStyle(
                          color: h.club != null ? c.secondaryText : c.tertiaryText,
                          fontSize: label * 0.9,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            );
          }),
          // Totals row
          Container(
            decoration: ShapeDecoration(
              color: c.cardBorder.withValues(alpha: 0.3),
              shape: SuperellipseShape(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                _dataFlex(1, 'TOT', label, c.tertiaryText, center: true),
                _dataFlex(1, '${round.totalPar}', label, c.tertiaryText, center: true),
                Expanded(
                  child: Center(
                    child: Text(
                      '${round.totalScore}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: c.primaryText,
                        fontSize: label,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                _dataFlex(1, '${round.totalPutts}', label, c.tertiaryText, center: true),
                const Expanded(child: SizedBox.shrink()),
                const Expanded(child: SizedBox.shrink()),
                if (hasClub) const Expanded(flex: 2, child: SizedBox.shrink()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerFlex(int flex, String text, double fontSize, {bool center = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: fontSize * 0.85,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _dataFlex(int flex, String text, double fontSize, Color color,
      {bool center = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
    );
  }

  Widget _statChip(
      AppColors c, String value, String label, Color color, double fontSize) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontFamily: 'Nunito',
                color: color,
                fontSize: fontSize * 1.05,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: TextStyle(
                color: c.tertiaryText, fontSize: fontSize * 0.85)),
      ],
    );
  }
}
