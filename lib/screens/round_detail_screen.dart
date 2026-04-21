import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/round.dart';
import '../models/hole_score.dart';
import '../models/group_round.dart';
import '../services/round_service.dart';
import '../theme/app_theme.dart';
import '../utils/l10n_extension.dart';
import '../widgets/weather_widgets.dart';
import 'shot_tracker_screen.dart' show ShotTrailMapView;

class RoundDetailScreen extends StatefulWidget {
  final Round round;
  const RoundDetailScreen({super.key, required this.round});

  @override
  State<RoundDetailScreen> createState() => _RoundDetailScreenState();
}

class _RoundDetailScreenState extends State<RoundDetailScreen> {
  final _screenshotController = ScreenshotController();
  final _shareButtonKey = GlobalKey();
  bool _sharing = false;

  // ── Group round (joint scorecard) ─────────────────────────────────────────
  GroupRound? _groupRound;
  /// uid → their Round (null if fetch failed)
  final Map<String, Round?> _peerRounds = {};
  bool _loadingGroupData = false;

  @override
  void initState() {
    super.initState();
    final sid = widget.round.sessionId;
    if (sid != null && sid.isNotEmpty) {
      _loadGroupData(sid);
    }
  }

  Future<void> _loadGroupData(String sessionId) async {
    if (!mounted) return;
    setState(() => _loadingGroupData = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('groupRounds')
          .doc(sessionId)
          .get();
      if (!doc.exists || !mounted) return;
      final gr = GroupRound.fromFirestore(doc);

      // Fetch each other player's Round for hole-by-hole scores.
      for (final player in gr.players.values) {
        final rid = player.roundId;
        if (rid == null || rid == widget.round.id) continue;
        try {
          final rdoc = await FirebaseFirestore.instance
              .collection('rounds')
              .doc(rid)
              .get();
          _peerRounds[player.uid] = rdoc.exists ? Round.fromFirestore(rdoc) : null;
        } catch (_) {
          _peerRounds[player.uid] = null;
        }
      }

      if (mounted) setState(() { _groupRound = gr; _loadingGroupData = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingGroupData = false);
    }
  }

  double get _sw => MediaQuery.of(context).size.width;
  double get _sh => MediaQuery.of(context).size.height;

  // ── Score colour coding ───────────────────────────────────────────────────
  Color _scoreColor(int diff) {
    if (diff <= -2) return const Color(0xFFFFD700);   // eagle or better → gold
    if (diff == -1) return const Color(0xFF5A9E1F);   // birdie → teal
    if (diff == 0)  return const Color(0xFF64B5F6);   // par → blue
    if (diff == 1)  return const Color(0xFFFFB74D);   // bogey → amber
    return const Color(0xFFE53935);                    // double bogey+ → red
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
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

      // Compute share origin from the button's render box (required on iOS).
      // Falls back to top-right of screen if button is scrolled out of view.
      Rect origin;
      final box = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && box.size.width > 0) {
        origin = box.localToGlobal(Offset.zero) & box.size;
      } else {
        final sz = MediaQuery.of(context).size;
        origin = Rect.fromLTWH(sz.width - 60, MediaQuery.of(context).padding.top + 8, 44, 44);
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${widget.round.courseName} — ${widget.round.scoreDiffLabel} (${widget.round.totalScore})',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share: $e')),
        );
      }
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
            Text(context.l10n.roundDetailDeleteTitle,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: c.primaryText,
                    fontSize: (sw * 0.052).clamp(18.0, 22.0),
                    fontWeight: FontWeight.w700)),
            SizedBox(height: sh * 0.008),
            Text(
              context.l10n.roundDetailDeleteConfirm(widget.round.courseName),
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
                      child: Text(context.l10n.cancel,
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
                      child: Text(context.l10n.delete,
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
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.primaryText, size: 20),
          onPressed: () => Navigator.of(context).pop(),
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
              key: _shareButtonKey,
              icon: Icon(Icons.ios_share_rounded, color: c.accent, size: 22),
              onPressed: _share,
              tooltip: context.l10n.roundDetailShare,
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFFF6B6B), size: 22),
            onPressed: _delete,
            tooltip: context.l10n.roundDetailDelete,
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
            SizedBox(height: _sh * 0.08),
            // ── Summary header card ────────────────────────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Green card
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
                  padding: EdgeInsets.only(
                    left: (_sw * 0.055).clamp(18.0, 24.0),
                    top: (_sw * 0.055).clamp(18.0, 24.0),
                    bottom: (_sw * 0.055).clamp(18.0, 24.0),
                    right: (_sw * 0.32).clamp(110.0, 140.0),
                  ),
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
                            ]),
                            if (round.courseRating != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'CR ${round.courseRating!.toStringAsFixed(1)} / S ${round.slopeRating ?? "-"}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: label * 0.88,
                                ),
                              ),
                            ],
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
                // Golfer image — large, bottom-right, overflows above card
                Positioned(
                  right: -100,
                  bottom: 0,
                  child: Image.network(
                    'https://raw.githubusercontent.com/grathi/stattee_profile_pic/main/Adobe%20Express%20-%20file.png',
                    height: (_sw * 0.55).clamp(180.0, 230.0),
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                    errorBuilder: (context, e, s) => const SizedBox.shrink(),
                  ),
                ),
              ],
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
                  _statChip(c, '${round.birdies}', context.l10n.roundsBirdies,
                      const Color(0xFF5A9E1F), label),
                  _statChip(c, '${round.pars}', context.l10n.roundsPars,
                      const Color(0xFF5A9E1F), label),
                  _statChip(c, '${round.bogeys}', context.l10n.roundsBogeys,
                      const Color(0xFFE53935), label),
                  _statChip(c, '${round.totalPutts}', context.l10n.roundsPutts,
                      c.secondaryText, label),
                  _statChip(
                      c,
                      round.fairwaysHitPct > 0
                          ? '${round.fairwaysHitPct.toStringAsFixed(0)}%'
                          : '-',
                      context.l10n.roundsFIR,
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
              context.l10n.roundDetailScorecard,
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

            // ── Joint scorecard (group rounds) ────────────────────────────
            if (widget.round.sessionId != null &&
                widget.round.sessionId!.isNotEmpty)
              _buildJointScorecardSection(c, round, body, label),

            // ── Shot trails section ────────────────────────────────────────
            _buildShotTrailsSection(c, round, body, label),
          ],
        ),
      ),
    );
  }

  // ── Joint scorecard section ────────────────────────────────────────────────
  Widget _buildJointScorecardSection(
      AppColors c, Round round, double body, double label) {
    if (_loadingGroupData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: _sh * 0.022),
          Text(
            'Group Scorecard',
            style: TextStyle(
              fontFamily: 'Nunito',
              color: c.primaryText,
              fontSize: body * 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: _sh * 0.012),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: c.accent, strokeWidth: 2),
            ),
          ),
        ],
      );
    }

    final gr = _groupRound;
    if (gr == null) return const SizedBox.shrink();

    // Build ordered list: current user first, then others by displayName.
    final myUid = round.userId;
    final ordered = <(GroupRoundPlayer, Round?)>[];
    final me = gr.players[myUid];
    if (me != null) ordered.add((me, round));
    final others = gr.players.values
        .where((p) => p.uid != myUid && p.roundId != null)
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    for (final p in others) {
      ordered.add((p, _peerRounds[p.uid]));
    }
    if (ordered.length < 2) return const SizedBox.shrink();

    // Par data: prefer GroupRound.holes, fall back to user's own scores.
    final Map<int, int> parByHole = {};
    if (gr.holes.isNotEmpty) {
      for (final h in gr.holes) parByHole[h.hole] = h.par;
    } else {
      for (final h in round.scores) parByHole[h.hole] = h.par;
    }

    final totalHoles = round.totalHoles;
    final holes = List.generate(totalHoles, (i) => i + 1);
    final front = holes.take(9).toList();
    final back = totalHoles > 9 ? holes.skip(9).toList() : <int>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: _sh * 0.028),
        Text(
          'Group Scorecard',
          style: TextStyle(
            fontFamily: 'Nunito',
            color: c.primaryText,
            fontSize: body * 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${gr.players.values.where((p) => p.status == 'completed').length} players · ${gr.courseName}',
          style: TextStyle(
            color: c.secondaryText,
            fontSize: label,
          ),
        ),
        SizedBox(height: _sh * 0.012),
        _JointScorecardTable(
          c: c,
          ordered: ordered,
          parByHole: parByHole,
          front: front,
          back: back,
          bodySize: body,
          labelSize: label,
          scoreColor: _scoreColor,
        ),
      ],
    );
  }

  // ── Shot Trails section ────────────────────────────────────────────────────
  Widget _buildShotTrailsSection(
      AppColors c, Round round, double body, double label) {
    final holesWithShots = round.scores
        .where((h) => h.shots?.isNotEmpty == true)
        .toList();
    if (holesWithShots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: _sh * 0.022),
        Text(
          context.l10n.roundDetailShotTrails,
          style: TextStyle(
            fontFamily: 'Nunito',
            color: c.primaryText,
            fontSize: body * 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: _sh * 0.012),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: holesWithShots.length,
            separatorBuilder: (context, i) => const SizedBox(width: 10),
            itemBuilder: (_, i) =>
                _trailChip(c, holesWithShots[i], body, label),
          ),
        ),
      ],
    );
  }

  Widget _trailChip(
      AppColors c, HoleScore h, double body, double label) {
    return GestureDetector(
      onTap: () => _showTrailSheet(h),
      child: Container(
        width: 86,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.accentBorder),
          boxShadow: [
            BoxShadow(
              color: c.accent.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on_rounded, color: c.accent, size: 18),
            const SizedBox(height: 4),
            Text(
              'Hole ${h.hole}',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: c.primaryText,
                fontSize: label,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${h.shots!.length - 1} shot${(h.shots!.length - 1) == 1 ? '' : 's'}',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: c.secondaryText,
                fontSize: label * 0.9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrailSheet(HoleScore h) {
    final shots = h.shots!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final sh = MediaQuery.of(context).size.height;
        final c = AppColors.of(context);
        return Container(
          height: sh * 0.65,
          decoration: BoxDecoration(
            color: c.sheetBg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: c.accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Hole ${h.hole} · ${shots.length} shots',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: c.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // Map
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28)),
                  child: ShotTrailMapView(
                    shots: shots,
                    holeNumber: h.hole,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
                _headerFlex(1, context.l10n.roundDetailHole, label, center: true),
                _headerFlex(1, context.l10n.roundDetailPar, label, center: true),
                _headerFlex(1, 'Score', label, center: true),
                _headerFlex(1, 'Putts', label, center: true),
                _headerFlex(1, 'FIR', label, center: true),
                _headerFlex(1, context.l10n.roundDetailGIR, label, center: true),
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
                _dataFlex(1, context.l10n.roundDetailTotal, label, c.tertiaryText, center: true),
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

// ── Joint scorecard table widget ──────────────────────────────────────────────

class _JointScorecardTable extends StatelessWidget {
  final AppColors c;
  final List<(GroupRoundPlayer, Round?)> ordered;
  final Map<int, int> parByHole;
  final List<int> front;
  final List<int> back;
  final double bodySize;
  final double labelSize;
  final Color Function(int diff) scoreColor;

  const _JointScorecardTable({
    required this.c,
    required this.ordered,
    required this.parByHole,
    required this.front,
    required this.back,
    required this.bodySize,
    required this.labelSize,
    required this.scoreColor,
  });

  // Returns the score for a given player+hole, or null if not available.
  int? _score(Round? r, int hole) =>
      r?.scores.firstWhere((h) => h.hole == hole,
          orElse: () => HoleScore(hole: hole, par: 0, score: 0, putts: 0, fairwayHit: false, gir: false)).score;

  bool _scoreExists(Round? r, int hole) =>
      r?.scores.any((h) => h.hole == hole) ?? false;

  // Sum scores for a list of holes.
  int? _sum(Round? r, List<int> holes) {
    if (r == null) return null;
    if (!holes.every((h) => _scoreExists(r, h))) return null;
    return holes.fold<int>(0, (s, h) => s + (_score(r, h) ?? 0));
  }

  int? _parSum(List<int> holes) {
    if (holes.any((h) => !parByHole.containsKey(h))) return null;
    return holes.fold<int>(0, (s, h) => s + parByHole[h]!);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    const nameColW = 88.0;
    const holeColW = 30.0;
    const subtotalW = 36.0;

    const headerGreen = Color(0xFF1A3A08);
    const parRowColor = Color(0xFF2E6B10);
    const altRow = Color(0xFFF4FAF0);

    // Build a section (front 9 / back 9 with subtotals).
    Widget buildSection(List<int> holeNums, String label) {
      if (holeNums.isEmpty) return const SizedBox.shrink();
      final parTotal = _parSum(holeNums);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hole header row ─────────────────────────────────────────────
          Container(
            color: headerGreen,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: nameColW,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      'PLAYER',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: labelSize * 0.78,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                ...holeNums.map((h) => SizedBox(
                      width: holeColW,
                      child: Text(
                        '$h',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: labelSize * 0.82,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )),
                SizedBox(
                  width: subtotalW,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: labelSize * 0.82,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Par row ─────────────────────────────────────────────────────
          Container(
            color: parRowColor,
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: nameColW,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      'PAR',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: labelSize * 0.78,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                ...holeNums.map((h) => SizedBox(
                      width: holeColW,
                      child: Text(
                        '${parByHole[h] ?? '-'}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: labelSize * 0.82,
                        ),
                      ),
                    )),
                SizedBox(
                  width: subtotalW,
                  child: Text(
                    '${parTotal ?? '-'}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: labelSize * 0.82,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Player rows ─────────────────────────────────────────────────
          ...ordered.asMap().entries.map((entry) {
            final idx = entry.key;
            final (player, round) = entry.value;
            final subtotal = _sum(round, holeNums);
            final parSub = _parSum(holeNums);
            final subtotalDiff =
                (subtotal != null && parSub != null) ? subtotal - parSub : null;

            return Container(
              color: idx.isOdd ? altRow : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  // Name
                  SizedBox(
                    width: nameColW,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        player.displayName.split(' ').first,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.primaryText,
                          fontSize: labelSize * 0.88,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  // Per-hole scores
                  ...holeNums.map((h) {
                    if (!_scoreExists(round, h)) {
                      return SizedBox(
                        width: holeColW,
                        child: Text('–',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: c.tertiaryText,
                                fontSize: labelSize * 0.82)),
                      );
                    }
                    final sc = _score(round, h)!;
                    final par = parByHole[h] ?? sc;
                    final diff = sc - par;
                    return SizedBox(
                      width: holeColW,
                      child: Center(child: _ScoreBadge(score: sc, diff: diff, size: holeColW - 4)),
                    );
                  }),
                  // Subtotal
                  SizedBox(
                    width: subtotalW,
                    child: Center(
                      child: subtotal == null
                          ? Text('–',
                              style: TextStyle(
                                  color: c.tertiaryText,
                                  fontSize: labelSize * 0.82))
                          : _SubtotalChip(
                              score: subtotal,
                              diff: subtotalDiff,
                              c: c,
                              labelSize: labelSize,
                            ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    }

    // Render each player's total separately below the table
    Widget buildPlayerTotals() {
      final allHoles = [...front, ...back];
      // Total row width must exactly match buildSection rows:
      //   nameColW + front.length*holeColW + subtotalW + back.length*holeColW + (back.isNotEmpty ? subtotalW : 0)
      final dataW = front.length * holeColW +
          subtotalW +
          back.length * holeColW +
          (back.isNotEmpty ? subtotalW : 0);
      final playerW =
          ordered.isNotEmpty ? dataW / ordered.length : dataW;
      return Container(
        color: c.cardBorder.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: nameColW,
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  'TOTAL',
                  style: TextStyle(
                    color: c.secondaryText,
                    fontSize: labelSize * 0.82,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            ...ordered.map((entry) {
              final (player, round) = entry;
              final total = _sum(round, allHoles) ?? player.totalScore;

              return SizedBox(
                width: playerW,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${total ?? '–'}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: c.primaryText,
                        fontSize: bodySize * 0.95,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      player.displayName.split(' ').first,
                      style: TextStyle(
                        color: c.tertiaryText,
                        fontSize: labelSize * 0.78,
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

    final squircle = SuperellipseShape(
      borderRadius: BorderRadius.circular(40),
      side: BorderSide(color: c.cardBorder),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: ShapeDecoration(
          color: c.cardBg,
          shape: squircle,
          shadows: c.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSection(front, 'OUT'),
            if (back.isNotEmpty) ...[
              const SizedBox(height: 1),
              buildSection(back, 'IN'),
            ],
            buildPlayerTotals(),
          ],
        ),
      ),
    );
  }
}

// Score badge — superellipse (squircle) shape mimicking real scorecard markings.
class _ScoreBadge extends StatelessWidget {
  final int score;
  final int diff;
  final double size;
  const _ScoreBadge({required this.score, required this.diff, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = diff <= -2
        ? const Color(0xFFFFD700)    // eagle+: gold
        : diff == -1
            ? const Color(0xFF5A9E1F) // birdie: green
            : diff == 0
                ? const Color(0xFF64B5F6) // par: blue
                : diff == 1
                    ? const Color(0xFFFFB74D) // bogey: amber
                    : const Color(0xFFE53935); // double+: red

    final double badgeSize = size * 0.82;

    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.3),
      ),
      alignment: Alignment.center,
      child: Text(
        '$score',
        style: TextStyle(
          fontFamily: 'Nunito',
          color: color,
          fontSize: badgeSize * 0.50,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
    );
  }
}

// Subtotal chip (OUT / IN column).
class _SubtotalChip extends StatelessWidget {
  final int score;
  final int? diff;
  final AppColors c;
  final double labelSize;
  const _SubtotalChip(
      {required this.score, required this.diff, required this.c, required this.labelSize});

  @override
  Widget build(BuildContext context) {
    final diffColor = diff == null
        ? c.primaryText
        : diff! < 0
            ? const Color(0xFF5A9E1F)
            : diff! == 0
                ? const Color(0xFF64B5F6)
                : const Color(0xFFFFB74D);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$score',
          style: TextStyle(
            fontFamily: 'Nunito',
            color: c.primaryText,
            fontSize: labelSize * 0.88,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (diff != null)
          Text(
            diff == 0 ? 'E' : diff! > 0 ? '+$diff' : '$diff',
            style: TextStyle(
              color: diffColor,
              fontSize: labelSize * 0.72,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}
