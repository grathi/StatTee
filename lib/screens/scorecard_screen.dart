import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import '../models/shot_position.dart';
import 'shot_tracker_screen.dart';
import '../models/hole_score.dart';
import '../services/round_service.dart';
import '../services/notification_service.dart';
import '../services/weather_service.dart';
import '../services/group_round_service.dart';
import '../services/golf_course_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tip_banner.dart';
import '../widgets/club_swipe_selector.dart';
import '../widgets/golf_animations.dart';
import '../services/onboarding_service.dart';
import 'round_summary_screen.dart';
import 'group_round_results_screen.dart';

class ScorecardScreen extends StatefulWidget {
  final String roundId;
  final String courseName;
  final int totalHoles;
  /// Course coordinates — used to fetch live weather during scoring.
  final double? lat;
  final double? lng;
  final void Function(String roundId)? onComplete;
  /// Hole to start on when resuming an unfinished round (1-indexed).
  final int initialHole;
  /// Previously saved hole scores to pre-populate the scorecard.
  final List<HoleScore> savedScores;
  /// Group session ID — set when playing with friends.
  final String? sessionId;
  /// Per-hole data from GolfCourseAPI (par, yardage, handicap).
  final List<GolfApiHole>? preloadedHoles;

  const ScorecardScreen({
    super.key,
    required this.roundId,
    required this.courseName,
    required this.totalHoles,
    this.lat,
    this.lng,
    this.onComplete,
    this.initialHole = 1,
    this.savedScores = const [],
    this.sessionId,
    this.preloadedHoles,
  });

  @override
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen>
    with TickerProviderStateMixin {
  int _currentHole = 1;
  int _par   = 4;
  int _score = 4;
  int _putts = 2;
  bool _fairwayHit = true;
  bool _gir        = false;
  List<String> _selectedClubs = [];
  bool _isSaving   = false;
  List<ShotPosition> _currentHoleShots = [];

  // GPS pin tracking
  Position? _userPos;
  StreamSubscription<Position>? _posSub;
  bool _weatherFetched = false;
  WeatherNow? _liveWeather;

  static const _clubs = [
    'Driver','3W','5W','4H','3I','4I','5I','6I','7I','8I','9I',
    'PW','GW','SW','LW','Putter',
  ];

  /// Carry distances (yards) for a ~18-handicap amateur.
  static const Map<String, int> _clubDistances = {
    'Driver': 220, '3W': 200, '5W': 185, '4H': 175,
    '3I': 165, '4I': 155, '5I': 145, '6I': 135,
    '7I': 125, '8I': 115, '9I': 105,
    'PW': 90, 'GW': 80, 'SW': 65, 'LW': 50,
    'Putter': 0,
  };

  // Completed hole scores saved so far
  final List<HoleScore> _saved = [];

  // Track when the round started to compute duration for calorie estimate
  final DateTime _roundStartTime = DateTime.now();

  late AnimationController _animCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _bounceCtrl;
  late Animation<double>   _bounceAnim;
  final int _slideDirection = 1;

  double get _sw => MediaQuery.of(context).size.width;
  double get _sh => MediaQuery.of(context).size.height;
  double get _hPad  => (_sw * 0.055).clamp(18.0, 28.0);
  double get _body  => (_sw * 0.036).clamp(13.0, 16.0);
  double get _label => (_sw * 0.030).clamp(11.0, 13.0);

  bool get _isLastHole => _currentHole == widget.totalHoles;

  int get _runningDiff =>
      _saved.fold(0, (s, h) => s + h.diff);

  String get _runningDiffLabel {
    if (_saved.isEmpty) return 'E';
    return _runningDiff == 0
        ? 'E'
        : _runningDiff > 0
            ? '+$_runningDiff'
            : '$_runningDiff';
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shimmerCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400))
      ..repeat();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));
    _saved.addAll(widget.savedScores);
    _resetForHole(widget.initialHole);
    _animCtrl.forward();
    _startGps();
  }

  Future<void> _startGps() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      const settings = LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
      );
      _posSub = Geolocator.getPositionStream(locationSettings: settings)
          .listen((pos) {
        if (mounted) {
          setState(() => _userPos = pos);
          // Fetch weather once: prefer course coords, fall back to device GPS
          if (!_weatherFetched) {
            _weatherFetched = true;
            final lat = widget.lat ?? pos.latitude;
            final lng = widget.lng ?? pos.longitude;
            WeatherService.getCurrentWeather(lat, lng).then((w) {
              if (mounted && w != null) setState(() => _liveWeather = w);
            });
          }
        }
      });

      // Also try fetching weather immediately from course coords (no GPS needed)
      if (!_weatherFetched && widget.lat != null && widget.lng != null) {
        _weatherFetched = true;
        WeatherService.getCurrentWeather(widget.lat!, widget.lng!).then((w) {
          if (mounted && w != null) setState(() => _liveWeather = w);
        });
      }
    } catch (_) {
      // GPS unavailable — feature silently disabled
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _shimmerCtrl.dispose();
    _bounceCtrl.dispose();
    _posSub?.cancel();
    super.dispose();
  }

  void _resetForHole(int hole) {
    // Check if we already have a saved score for this hole (editing)
    final existing = _saved.where((h) => h.hole == hole).firstOrNull;
    // Look up par from API data if no saved score yet
    final apiPar = widget.preloadedHoles
        ?.where((h) => h.hole == hole)
        .firstOrNull
        ?.par;
    setState(() {
      _currentHole = hole;
      _par         = existing?.par   ?? apiPar ?? 4;
      _score       = existing?.score ?? apiPar ?? 4;
      _putts       = existing?.putts ?? 2;
      _fairwayHit  = existing?.fairwayHit ?? true;
      _gir         = existing?.gir        ?? false;
      _selectedClubs = existing?.club != null
          ? existing!.club!.split(',').where((s) => s.isNotEmpty).toList()
          : [];
      _currentHoleShots = existing?.shots?.toList() ?? [];
    });
    _animCtrl
      ..reset()
      ..forward();
  }

  Future<void> _openShotTracker() async {
    // Course coords take priority — the map should open on the course,
    // not the user's current GPS location (which may be elsewhere).
    LatLng? initial;
    if (widget.lat != null && widget.lng != null) {
      initial = LatLng(widget.lat!, widget.lng!);
    } else if (_userPos != null) {
      initial = LatLng(_userPos!.latitude, _userPos!.longitude);
    }
    final shots = await Navigator.push<List<ShotPosition>>(
      context,
      MaterialPageRoute(
        builder: (_) => ShotTrackerScreen(
          holeNumber: _currentHole,
          par: _par,
          initialPosition: initial,
          targetPin: initial,
          // Restore any shots already tracked for this hole so re-opening
          // the tracker never loses prior work.
          initialShots: List.of(_currentHoleShots),
          // Ghost-layer: all previously completed holes that have shot data.
          previousHolesShots: _saved
              .where((h) => h.shots?.isNotEmpty == true)
              .map((h) => List<ShotPosition>.of(h.shots!))
              .toList(),
        ),
      ),
    );
    if (shots != null && mounted) {
      setState(() {
        _currentHoleShots = shots;
        // shots[0] is the tee marker, so stroke count = shots.length - 1.
        // Only auto-fill if the score hasn't been changed yet.
        if (shots.length > 1 && _score == _par) {
          _score = (shots.length - 1).clamp(1, 15);
        }
      });
    }
  }

  void _scoreChanged(int v, {int? newPar}) {
    setState(() {
      if (newPar != null) _par = newPar;
      _score = v.clamp(1, 15);
      if (_putts > _score) _putts = _score;
    });
  }

  Future<void> _saveAndAdvance() async {
    setState(() => _isSaving = true);
    final hs = HoleScore(
      hole:       _currentHole,
      par:        _par,
      score:      _score,
      putts:      _putts,
      fairwayHit: _fairwayHit,
      gir:        _gir,
      club:       _selectedClubs.isNotEmpty ? _selectedClubs.join(',') : null,
      shots:      _currentHoleShots.isNotEmpty ? List.unmodifiable(_currentHoleShots) : null,
    );

    try {
      await RoundService.saveHoleScore(widget.roundId, hs);
      // Update local list
      final idx = _saved.indexWhere((h) => h.hole == _currentHole);
      if (idx >= 0) {
        _saved[idx] = hs;
      } else {
        _saved.add(hs);
      }

      if (_isLastHole) {
        if (mounted) CloudSyncPulse.show(context);
        await _completeRound();
      } else {
        if (mounted) GolfSaveOverlay.show(context);
        if (mounted) CloudSyncPulse.show(context);
        final nextHole = _currentHole + 1;
        // Persist the current hole position so the round can be resumed.
        unawaited(RoundService.saveCurrentHole(widget.roundId, nextHole));
        _resetForHole(nextHole);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving: $e'),
              backgroundColor: const Color(0xFFE53935)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _completeRound() async {
    await RoundService.completeRound(widget.roundId);

    // Check for personal best and fire notification
    try {
      final allRounds = await RoundService.allCompletedRoundsStream().first;
      final completedRounds = allRounds
          .where((r) => r.id != widget.roundId && r.totalHoles == widget.totalHoles)
          .toList();
      final thisScore = _saved.fold(0, (s, h) => s + h.score);
      if (completedRounds.isNotEmpty) {
        final prevBest = completedRounds
            .map((r) => r.totalScore)
            .reduce((a, b) => a < b ? a : b);
        if (thisScore < prevBest) {
          await NotificationService.showPersonalBest(thisScore);
        }
      }
      // Re-evaluate streak (round just completed = reset the counter)
      await NotificationService.evaluateStreak(DateTime.now());
    } catch (_) {}

    // Report to group session if playing with friends
    if (widget.sessionId != null) {
      try {
        final totalScore = _saved.fold(0, (s, h) => s + h.score);
        final totalPar   = _saved.fold(0, (s, h) => s + h.par);
        await GroupRoundService.reportCompletion(
          widget.sessionId!,
          roundId:    widget.roundId,
          totalScore: totalScore,
          scoreDiff:  (totalScore - totalPar).toDouble(),
        );
      } catch (_) {}
    }

    if (!mounted) return;
    widget.onComplete?.call(widget.roundId);

    // Navigate to group results if part of a session, otherwise normal summary
    if (widget.sessionId != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GroupRoundResultsScreen(
            sessionId:  widget.sessionId!,
            myRoundId:  widget.roundId,
            courseName: widget.courseName,
          ),
        ),
      );
    } else {
      _showRoundSummary();
    }
  }

  void _showRoundSummary() {
    final putts      = _saved.fold(0, (s, h) => s + h.putts);
    final fhit       = _saved.where((h) => h.par >= 4 && h.fairwayHit).length;
    final ftotal     = _saved.where((h) => h.par >= 4).length;
    final gir        = _saved.where((h) => h.gir).length;
    final birdies    = _saved.where((h) => h.diff == -1).length;
    final pars       = _saved.where((h) => h.diff == 0).length;
    final bogeys     = _saved.where((h) => h.diff == 1).length;
    final doublePlus = _saved.where((h) => h.diff >= 2).length;
    final front9     = _saved.take(9).fold(0, (s, h) => s + h.score);
    final back9      = _saved.skip(9).fold(0, (s, h) => s + h.score);
    final bestHole   = _saved.isEmpty ? 1 : _saved.reduce((a, b) => a.diff <= b.diff ? a : b).hole;
    final worstHole  = _saved.isEmpty ? 1 : _saved.reduce((a, b) => a.diff >= b.diff ? a : b).hole;
    final duration   = DateTime.now().difference(_roundStartTime).inMinutes;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) => RoundSummaryScreen(
          roundId:         widget.roundId,
          courseName:      widget.courseName,
          totalHoles:      widget.totalHoles,
          totalScore:      _saved.fold(0, (s, h) => s + h.score),
          totalPar:        _saved.fold(0, (s, h) => s + h.par),
          front9:          front9,
          back9:           back9,
          putts:           putts,
          fairwaysHit:     fhit,
          fairwaysTotal:   ftotal,
          gir:             gir,
          birdies:         birdies,
          pars:            pars,
          bogeys:          bogeys,
          doublePlus:      doublePlus,
          bestHole:        bestHole,
          worstHole:       worstHole,
          durationMinutes: duration,
          carriedBag:      true,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final anim = CurvedAnimation(
              parent: animation, curve: Curves.easeInOutCubic);
          return AnimatedBuilder(
            animation: anim,
            builder: (context, w) => ClipOval(
              clipper: _RadialExpandClipper(progress: anim.value),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(anim),
                child: FadeTransition(opacity: animation, child: child),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Plays Like distance (adjusts yardage for wind) ────────────────────────
  int _playsLike(int baseYds) {
    if (_liveWeather == null || baseYds == 0) return baseYds;
    final wind = _liveWeather!.windSpeed;
    return (baseYds + wind * 0.8).round();
  }

  // ── Club recommendation ────────────────────────────────────────────────────
  List<String> get _recommendedClubs {
    if (widget.preloadedHoles == null) return [];
    final holeData = widget.preloadedHoles!
        .where((h) => h.hole == _currentHole).firstOrNull;
    if (holeData == null || holeData.yardage <= 0) return [];

    final target = _playsLike(holeData.yardage);

    final candidates = _clubDistances.entries
        .where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (_par == 3) {
      final primary = candidates.lastWhere(
        (e) => e.value >= target, orElse: () => candidates.last);
      final idx = candidates.indexOf(primary);
      final secondary = idx > 0 ? candidates[idx - 1] : null;
      return [primary.key, if (secondary != null) secondary.key];
    } else {
      const idealApproach = 115;
      final desiredDrive = target - idealApproach;
      if (desiredDrive <= 0) return ['7I', '8I'];
      final primary = candidates.lastWhere(
        (e) => e.value <= desiredDrive, orElse: () => candidates.first);
      final idx = candidates.indexOf(primary);
      final secondary = idx < candidates.length - 1 ? candidates[idx + 1] : null;
      return [primary.key, if (secondary != null) secondary.key];
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: Container(
        color: c.scaffoldBg,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(c),
              _buildProgressDots(c),
              TipBanner(
                title: 'Scoring a Round',
                body: 'Enter your score, putts, fairway and GIR for each hole. Tap the club to track your club selection.',
                hasSeenFn: OnboardingService.hasSeenScorecardTip,
                markSeenFn: OnboardingService.markScorecardTipSeen,
              ),
              SizedBox(height: _sh * 0.012),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: _hPad),
                  child: Column(
                    children: [
                      SizedBox(height: _sh * 0.016),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        transitionBuilder: (child, anim) {
                          final dir = _slideDirection;
                          final slideIn = Tween<Offset>(
                            begin: Offset(0.18 * dir, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                              parent: anim, curve: Curves.easeOutCubic));
                          return SlideTransition(
                            position: slideIn,
                            child: FadeTransition(opacity: anim, child: child),
                          );
                        },
                        child: _buildHoleHeroCard(c, key: ValueKey(_currentHole)),
                      ),
                      SizedBox(height: _sh * 0.014),
                      _buildSmartCaddyCard(c),
                      SizedBox(height: _sh * 0.014),
                      _buildScoringCard(c),
                      SizedBox(height: _sh * 0.018),
                      if (_saved.isNotEmpty) _buildPreviousHoles(c),
                      SizedBox(height: _sh * 0.02),
                    ],
                  ),
                ),
              ),
              _buildNextButton(c),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(AppColors c) {
    return Padding(
      padding: EdgeInsets.fromLTRB(_hPad, _sh * 0.012, _hPad, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showAbandonDialog(c),
            child: Container(
              width: (_sw * 0.095).clamp(34.0, 44.0),
              height: (_sw * 0.095).clamp(34.0, 44.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.accentBg,
                border: Border.all(color: c.accentBorder),
              ),
              child: Icon(Icons.close_rounded,
                  color: c.accent, size: _body * 1.1),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.courseName,
                  style: TextStyle(fontFamily: 'Nunito',
                    color: c.primaryText,
                    fontSize: _body,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Hole $_currentHole / ${widget.totalHoles}',
                  style: TextStyle(color: c.secondaryText, fontSize: _label),
                  textAlign: TextAlign.center,
                ),
                if (widget.sessionId != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_rounded, size: 12, color: c.accent),
                      const SizedBox(width: 3),
                      Text('Playing with friends',
                          style: TextStyle(color: c.accent, fontSize: _label * 0.9, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
                if (_liveWeather != null) ...[
                  const SizedBox(height: 2),
                  _WeatherChip(weather: _liveWeather!, label: _label),
                ],
              ],
            ),
          ),
          // Running total
          if (_saved.isNotEmpty && _runningDiff != 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _runningDiff < 0
                    ? c.accent.withValues(alpha: 0.15)
                    : const Color(0xFFE53935).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _runningDiff < 0
                      ? c.accent.withValues(alpha: 0.40)
                      : const Color(0xFFE53935).withValues(alpha: 0.40),
                ),
              ),
              child: Text(
                _runningDiffLabel,
                style: TextStyle(fontFamily: 'Nunito',
                  color: _runningDiff < 0 ? c.accent : const Color(0xFFE53935),
                  fontSize: _body,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            SizedBox(width: (_sw * 0.095).clamp(34.0, 44.0)),
        ],
      ),
    );
  }

  // ── Progress dots ──────────────────────────────────────────────────────────
  Widget _buildProgressDots(AppColors c) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _hPad, vertical: _sh * 0.016),
      child: Row(
        children: List.generate(widget.totalHoles, (i) {
          final hole = i + 1;
          final isDone    = _saved.any((h) => h.hole == hole);
          final isCurrent = hole == _currentHole;
          return Expanded(
            child: GestureDetector(
              onTap: isDone ? () => _resetForHole(hole) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                height: isCurrent ? 6 : 4,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? c.accent
                      : isDone
                          ? c.accent.withValues(alpha: 0.45)
                          : c.cardBorder,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }


  // ── Number tile grid (score / putts picker) ────────────────────────────────
  Widget _numberTiles({
    required BuildContext context,
    required List<int> values,
    required int selected,
    required int? par,           // if set, tiles get score-relative colour
    required void Function(int) onSelect,
    required AppColors c,
    required double sw,
    required double label,
  }) {
    Color tileColor(int v) {
      if (par == null) return c.accent; // putts — always accent
      final d = v - par;
      if (d <= -2) return const Color(0xFFFFD700);       // eagle+
      if (d == -1) return const Color(0xFF4CAF82);       // birdie
      if (d == 0)  return const Color(0xFF64B5F6);       // par
      if (d == 1)  return const Color(0xFFFFB74D);       // bogey
      return const Color(0xFFE53935);                    // double+
    }

    final tileSize = (sw * 0.135).clamp(44.0, 56.0);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) {
        final isSel = v == selected;
        final col   = tileColor(v);
        return GestureDetector(
          onTap: () => onSelect(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            width: tileSize,
            height: tileSize,
            decoration: ShapeDecoration(
              color: isSel ? col : c.fieldBg,
              shape: SuperellipseShape(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSel ? col : c.fieldBorder,
                  width: isSel ? 0 : 1,
                ),
              ),
            ),
            child: Center(
              child: Text(
                '$v',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  color: isSel ? Colors.white : c.secondaryText,
                  fontSize: (sw * 0.048).clamp(16.0, 22.0),
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Edit hole bottom sheet ─────────────────────────────────────────────────
  Future<void> _showEditHoleSheet(HoleScore original) async {
    final c = AppColors.of(context);
    int par        = original.par;
    int score      = original.score;
    int putts      = original.putts;
    bool fairway   = original.fairwayHit;
    bool gir       = original.gir;
    String? club   = original.club;
    bool saving    = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final sw = MediaQuery.of(ctx).size.width;
          final sh = MediaQuery.of(ctx).size.height;
          final body  = (sw * 0.036).clamp(13.0, 16.0);
          final label = (sw * 0.030).clamp(11.0, 13.0);
          final hPad  = (sw * 0.055).clamp(18.0, 28.0);

          Widget sectionLabel(String t) => Align(
                alignment: Alignment.centerLeft,
                child: Text(t,
                    style: TextStyle(
                        color: c.secondaryText,
                        fontSize: label,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
              );

          Widget toggle(String t, bool val, IconData icon, void Function(bool) onChanged) =>
              Expanded(
                child: GestureDetector(
                  onTap: () => setSheet(() => onChanged(!val)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: EdgeInsets.symmetric(
                        horizontal: (sw * 0.032).clamp(10.0, 16.0),
                        vertical: (sh * 0.014).clamp(10.0, 14.0)),
                    decoration: BoxDecoration(
                      color: val ? c.accentBg : c.fieldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: val ? c.accentBorder : c.fieldBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: val ? c.accent : c.tertiaryText, size: body * 1.1),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(t,
                              style: TextStyle(
                                  color: val ? c.accent : c.secondaryText,
                                  fontSize: label,
                                  fontWeight: val ? FontWeight.w600 : FontWeight.w400),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              );


          return Container(
            decoration: BoxDecoration(
              color: c.sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: c.cardBorder)),
            ),
            padding: EdgeInsets.fromLTRB(
                hPad, 20, hPad,
                MediaQuery.of(ctx).viewInsets.bottom + hPad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: c.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Row(
                  children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.accentBg,
                        border: Border.all(color: c.accentBorder),
                      ),
                      child: Center(
                        child: Text('${original.hole}',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                color: c.accent,
                                fontSize: body,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Edit Hole ${original.hole}',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            color: c.primaryText,
                            fontSize: body * 1.1,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                SizedBox(height: sh * 0.022),
                // Par
                sectionLabel('Par'),
                SizedBox(height: sh * 0.010),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [3, 4, 5].map((p) {
                    final sel = par == p;
                    return GestureDetector(
                      onTap: () => setSheet(() { par = p; }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: (sw * 0.18).clamp(58.0, 72.0),
                        height: (sw * 0.13).clamp(42.0, 54.0),
                        decoration: BoxDecoration(
                          color: sel ? c.accent : c.fieldBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: sel ? c.accent : c.fieldBorder),
                        ),
                        child: Center(
                          child: Text('$p',
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  color: sel ? Colors.white : c.secondaryText,
                                  fontSize: body * 1.2,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: sh * 0.022),
                // Score
                sectionLabel('Score'),
                SizedBox(height: sh * 0.010),
                _numberTiles(
                  context: ctx,
                  values: List.generate(12, (i) => i + 1),
                  selected: score,
                  par: par,
                  onSelect: (v) => setSheet(() => score = v),
                  c: c, sw: sw, label: label,
                ),
                SizedBox(height: sh * 0.022),
                // Putts
                sectionLabel('Putts'),
                SizedBox(height: sh * 0.010),
                _numberTiles(
                  context: ctx,
                  values: List.generate(7, (i) => i),
                  selected: putts,
                  par: null,
                  onSelect: (v) => setSheet(() => putts = v),
                  c: c, sw: sw, label: label,
                ),
                SizedBox(height: sh * 0.022),
                // Fairway + GIR toggles
                Row(
                  children: [
                    toggle('Fairway Hit', fairway, Icons.grass_rounded,
                        (v) => fairway = v),
                    const SizedBox(width: 10),
                    toggle('GIR', gir, Icons.sports_golf_rounded, (v) => gir = v),
                  ],
                ),
                SizedBox(height: sh * 0.026),
                // Save button
                SizedBox(
                  width: double.infinity,
                  height: (sh * 0.068).clamp(48.0, 60.0),
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setSheet(() => saving = true);
                            final updated = HoleScore(
                              hole:       original.hole,
                              par:        par,
                              score:      score,
                              putts:      putts,
                              fairwayHit: fairway,
                              gir:        gir,
                              club:       club,
                            );
                            await RoundService.saveHoleScore(widget.roundId, updated);
                            if (!mounted) return;
                            setState(() {
                            final idx = _saved.indexWhere((h) => h.hole == original.hole);
                            if (idx >= 0) _saved[idx] = updated;
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A9E1F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(Colors.white)),
                          )
                        : Text('Save Changes',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: (sw * 0.046).clamp(16.0, 20.0),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Previous holes strip ───────────────────────────────────────────────────
  Widget _buildPreviousHoles(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCORECARD',
          style: TextStyle(fontFamily: 'Nunito',
              color: c.secondaryText,
              fontSize: _label,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5),
        ),
        SizedBox(height: _sh * 0.010),
        Container(
          decoration: ShapeDecoration(
            color: c.cardBg,
            shape: SuperellipseShape(
              borderRadius: BorderRadius.circular(32),
              side: BorderSide(color: c.cardBorder),
            ),
            shadows: c.cardShadow,
          ),
          child: Column(
            children: _saved.map((h) {
              final diff  = h.score - h.par;
              final color = _scoreColor(diff);
              final label = _scoreLabel(diff);
              return GestureDetector(
                onTap: () => _resetForHole(h.hole),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: (_sw * 0.045).clamp(14.0, 20.0),
                      vertical: (_sh * 0.012).clamp(8.0, 14.0)),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: h == _saved.last
                                ? Colors.transparent
                                : c.divider)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.15),
                        ),
                        child: Center(
                          child: Text(
                            '${h.hole}',
                            style: TextStyle(
                                color: color,
                                fontSize: _label,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Par ${h.par}',
                          style: TextStyle(
                              color: c.secondaryText,
                              fontSize: _label)),
                      const Spacer(),
                      Text(
                        label,
                        style: TextStyle(
                            color: color,
                            fontSize: _label,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${h.score}',
                            style: TextStyle(fontFamily: 'Nunito',
                                color: color,
                                fontSize: _body,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _showEditHoleSheet(h),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c.accentBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: c.accentBorder),
                          ),
                          child: Icon(Icons.edit_rounded,
                              color: c.accent, size: _label),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Next / Complete button ─────────────────────────────────────────────────
  Widget _buildNextButton(AppColors c) {
    final label = _isLastHole ? 'Finish Round' : 'Next Hole';
    return Padding(
      padding: EdgeInsets.fromLTRB(_hPad, 0, _hPad, (_sh * 0.025).clamp(16.0, 28.0)),
      child: GestureDetector(
        onTap: _isSaving ? null : _saveAndAdvance,
        child: AnimatedBuilder(
          animation: _shimmerCtrl,
          builder: (_, child) {
            return Container(
              height: (_sh * 0.068).clamp(52.0, 64.0),
              decoration: ShapeDecoration(
                gradient: LinearGradient(
                  colors: [c.accent, c.accent.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: SuperellipseShape(borderRadius: BorderRadius.circular(40)),
                shadows: [
                  BoxShadow(
                    color: c.accent.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipPath(
                clipper: _SuperellipseClipper(radius: 40),
                child: Stack(
                  children: [
                    // Shimmer sweep
                    Positioned.fill(
                      child: FractionalTranslation(
                        translation: Offset(_shimmerCtrl.value * 2.5 - 0.75, 0),
                        child: Transform(
                          transform: Matrix4.skewX(-0.3),
                          child: Container(
                            width: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.22),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: _isSaving
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(Colors.white)))
                          : Text(
                              label,
                              style: const TextStyle(
                                color:      Colors.white,
                                fontFamily: 'Nunito',
                                fontSize:   17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  Widget _buildHoleHeroCard(AppColors c, {Key? key}) {
    final holeData = (widget.preloadedHoles != null &&
            _currentHole <= widget.preloadedHoles!.length)
        ? widget.preloadedHoles![_currentHole - 1]
        : null;
    final hasYds = holeData != null && holeData.yardage > 0;
    final hPad = (_sw * 0.055).clamp(18.0, 26.0);

    final diff       = _runningDiff;
    final diffLabel  = diff == 0 ? 'E' : (diff > 0 ? '+$diff' : '$diff');
    final diffColor  = diff < 0 ? c.accent : diff > 0 ? const Color(0xFFFF7B7B) : c.primaryText;

    return Container(
      key: key,
      width: double.infinity,
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(borderRadius: BorderRadius.circular(28)),
        shadows: c.cardShadow,
      ),
      child: ClipPath(
        clipper: _SuperellipseClipper(radius: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top section ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, (_sh * 0.018).clamp(14.0, 20.0), hPad, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hole badge
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color:  c.accentBg,
                      shape:  BoxShape.circle,
                      border: Border.all(color: c.accentBorder),
                    ),
                    child: Center(
                      child: Text(
                        '$_currentHole',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color:      c.accent,
                          fontSize:   (_sw * 0.040).clamp(14.0, 17.0),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: (_sw * 0.030).clamp(10.0, 14.0)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HOLE $_currentHole',
                          style: TextStyle(
                            color:      c.primaryText,
                            fontSize:   (_sw * 0.044).clamp(15.0, 20.0),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          holeData != null
                              ? 'PAR $_par  ·  HCP ${holeData.handicap}'
                              : 'PAR $_par',
                          style: TextStyle(
                            color:      c.secondaryText,
                            fontSize:   (_sw * 0.030).clamp(11.0, 13.0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Running diff badge
                  if (_saved.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: diffColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: diffColor.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        diffLabel,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color:      diffColor,
                          fontSize:   (_sw * 0.032).clamp(11.0, 14.0),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Hero yardage + mini-map ────────────────────────────────
            if (hasYds) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, (_sh * 0.012).clamp(8.0, 14.0), hPad, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Yardage + Plays Like
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                // ignore: unnecessary_non_null_assertion
                                '${holeData!.yardage}',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  color:      c.accent,
                                  fontSize:   (_sw * 0.20).clamp(68.0, 88.0),
                                  fontWeight: FontWeight.w900,
                                  height:     0.9,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  'YDS',
                                  style: TextStyle(
                                    color:         c.secondaryText,
                                    fontSize:      (_sw * 0.038).clamp(13.0, 17.0),
                                    fontWeight:    FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Plays Like chip (only when weather available)
                          if (_liveWeather != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: c.iconContainerBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: c.cardBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.air_rounded,
                                      color: c.secondaryText, size: 11),
                                  const SizedBox(width: 4),
                                  Text(
                                    'PLAYS LIKE ${_playsLike(holeData.yardage)} YDS',
                                    style: TextStyle(
                                      color:         c.secondaryText,
                                      fontSize:      (_sw * 0.024).clamp(9.0, 11.0),
                                      fontWeight:    FontWeight.w600,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Mini-map
                    _HoleMiniMap(par: _par, size: (_sw * 0.22).clamp(72.0, 90.0), c: c),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(height: (_sh * 0.014).clamp(10.0, 14.0)),
            ],

            // ── Segmented par control ─────────────────────────────────
            Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(hPad, (_sh * 0.014).clamp(8.0, 14.0), hPad, (_sh * 0.016).clamp(10.0, 16.0)),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: c.fieldBg,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: c.fieldBorder),
              ),
              child: Row(
                children: [3, 4, 5].map((p) {
                  final sel = _par == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _scoreChanged(_score, newPar: p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? c.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: sel ? [BoxShadow(
                            color: c.accent.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          )] : null,
                        ),
                        child: Center(
                          child: Text(
                            'PAR $p',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color:      sel ? Colors.white : c.secondaryText,
                              fontSize:   (_sw * 0.030).clamp(11.0, 13.0),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _smartCaddyTip() {
    if (_saved.length < 3) {
      if (_par == 3) return 'Par 3: commit to one club and trust the swing.';
      return 'Play your game — insights unlock after 3 holes.';
    }
    final avgPutts = _saved.fold(0, (s, h) => s + h.putts) / _saved.length;
    final fhTotal  = _saved.where((h) => h.par >= 4).length;
    final fhCount  = _saved.where((h) => h.par >= 4 && h.fairwayHit).length;
    final girCount = _saved.where((h) => h.gir).length;
    if (avgPutts > 2.3) {
      return 'Averaging \${avgPutts.toStringAsFixed(1)} putts — focus on lag putting from distance.';
    }
    if (fhTotal > 0 && fhCount / fhTotal < 0.4) {
      return 'Only \${(fhCount / fhTotal * 100).round()}% fairways hit — consider a 3-wood off the tee.';
    }
    if (_saved.isNotEmpty && girCount / _saved.length < 0.3) {
      return 'Approaches struggling — aim for the fat of the green today.';
    }
    if (_par == 3) return 'Par 3: commit to one club and trust the swing.';
    return 'Solid round so far — keep the same rhythm and tempo.';
  }

  Widget _buildSmartCaddyCard(AppColors c) {
    const aiColor = Color(0xFF7C5CFC); // AI purple
    final tip = _smartCaddyTip();

    return Container(
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: aiColor.withValues(alpha: 0.25)),
        ),
        shadows: c.cardShadow,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: _hPad * 0.85,
          vertical:   (_sh * 0.018).clamp(12.0, 18.0),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon box
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color:        aiColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: aiColor.withValues(alpha: 0.30)),
              ),
              child: Center(
                child: Text('✦', style: TextStyle(fontSize: 14, color: aiColor)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'AI CADDY',
                        style: TextStyle(
                          color:         aiColor,
                          fontSize:      10.0,
                          fontWeight:    FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Pulsing dot
                      AnimatedBuilder(
                        animation: _shimmerCtrl,
                        builder: (context, w) => Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            color:  aiColor.withValues(alpha: 0.4 + _shimmerCtrl.value * 0.6),
                            shape:  BoxShape.circle,
                            boxShadow: [BoxShadow(
                              color: aiColor.withValues(alpha: _shimmerCtrl.value * 0.4),
                              blurRadius: 4,
                            )],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Text(
                      tip,
                      key: ValueKey('${_saved.length}_$_par'),
                      style: TextStyle(
                        color:      c.primaryText,
                        fontSize:   13.5,
                        fontWeight: FontWeight.w500,
                        height:     1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoringCard(AppColors c) {
    final diff       = _score - _par;
    final scoreCol   = _scoreColor(diff);
    final scoreLabel = _scoreLabel(diff);
    final puttsMax   = _score.clamp(0, 6);

    return Container(
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      child: Padding(
        padding: EdgeInsets.all(_hPad * 0.85),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Score label row ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('SCORE', style: TextStyle(
                  color: c.tertiaryText, fontSize: _label * 0.85,
                  fontWeight: FontWeight.w700, letterSpacing: 1.2,
                )),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    scoreLabel,
                    key: ValueKey(scoreLabel),
                    style: TextStyle(
                      color: scoreCol, fontSize: _label,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: _sh * 0.014),
            _ScoreStepperWidget(
              value:      _score,
              scoreColor: scoreCol,
              bounceAnim: _bounceAnim,
              bounceCtrl: _bounceCtrl,
              c:          c,
              sw:         _sw,
              sh:         _sh,
              onStep: (delta) {
                _scoreChanged((_score + delta).clamp(1, 15).toInt());
              },
            ),

            SizedBox(height: _sh * 0.024),
            Divider(color: c.divider, height: 1),
            SizedBox(height: _sh * 0.020),

            // ── Putts row ───────────────────────────────────────────────
            Text('PUTTS', style: TextStyle(
              color: c.tertiaryText, fontSize: _label * 0.85,
              fontWeight: FontWeight.w700, letterSpacing: 1.2,
            )),
            SizedBox(height: _sh * 0.012),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: List.generate(puttsMax + 1, (i) {
                final sel  = _putts == i;
                final size = (_sw * 0.13).clamp(48.0, 58.0);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _putts = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    width: size, height: size,
                    decoration: BoxDecoration(
                      color:  sel ? c.accent : c.fieldBg,
                      shape:  BoxShape.circle,
                      border: Border.all(
                        color: sel ? c.accent : c.fieldBorder,
                        width: sel ? 0 : 1.5,
                      ),
                      boxShadow: sel ? [BoxShadow(
                        color: c.accent.withValues(alpha: 0.35),
                        blurRadius: 10, offset: const Offset(0, 4),
                      )] : null,
                    ),
                    child: Center(
                      child: Text('$i', style: TextStyle(
                        fontFamily: 'Nunito',
                        color:      sel ? Colors.white : c.secondaryText,
                        fontSize:   (_sw * 0.044).clamp(15.0, 20.0),
                        fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                      )),
                    ),
                  ),
                );
              }),
            ),

            SizedBox(height: _sh * 0.024),
            Divider(color: c.divider, height: 1),
            SizedBox(height: _sh * 0.020),

            // ── Fairway Hit + GIR toggles ───────────────────────────────
            if (_par >= 4) ...[
              _BigToggle(
                label: 'FAIRWAY HIT', icon: Icons.grass_rounded,
                value: _fairwayHit, c: c, sw: _sw, sh: _sh,
                onTap: () => setState(() => _fairwayHit = !_fairwayHit),
              ),
              SizedBox(height: _sh * 0.012),
            ],
            _BigToggle(
              label: 'GREEN IN REGULATION', icon: Icons.flag_rounded,
              value: _gir, c: c, sw: _sw, sh: _sh,
              onTap: () => setState(() => _gir = !_gir),
            ),

            SizedBox(height: _sh * 0.020),

            // ── Shot tracker ─────────────────────────────────────────────
            GestureDetector(
              onTap: _openShotTracker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _currentHoleShots.isNotEmpty ? c.accentBg : c.cardBg,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: c.accentBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _currentHoleShots.isNotEmpty
                          ? Icons.location_on_rounded
                          : Icons.my_location_rounded,
                      size: _label * 1.1,
                      color: c.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _currentHoleShots.isEmpty
                          ? 'Track shots'
                          : _currentHoleShots.length == 1
                              ? 'Tee set'
                              : '${_currentHoleShots.length - 1} shot${(_currentHoleShots.length - 1) == 1 ? '' : 's'} tracked',
                      style: TextStyle(
                        fontSize: _label,
                        color: c.accent,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    if (_currentHoleShots.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle_rounded,
                          size: _label, color: c.accent),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: _sh * 0.020),

            // ── Club selector ────────────────────────────────────────────
            Text('CLUB', style: TextStyle(
              color: c.tertiaryText, fontSize: _label * 0.85,
              fontWeight: FontWeight.w700, letterSpacing: 1.2,
            )),
            SizedBox(height: _sh * 0.012),
            ClubSwipeSelector(
              clubs: _clubs,
              recommendedClubs: _recommendedClubs,
              selectedClubs: _selectedClubs,
              maxSelections: _score,
              onClubsChanged: (clubs) => setState(() => _selectedClubs = clubs),
            ),

            SizedBox(height: _sh * 0.020),
          ],
        ),
      ),
    );
  }

  // ── Abandon dialog ─────────────────────────────────────────────────────────
  void _showAbandonDialog(AppColors c) {
    final sw = _sw;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => Dialog(
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
                  color: c.accentBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.accentBorder),
                ),
                child: Icon(Icons.flag_rounded, color: c.accent, size: 26),
              ),
              const SizedBox(height: 16),
              Text('Leave Round?',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: c.primaryText,
                    fontSize: (sw * 0.052).clamp(18.0, 22.0),
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 8),
              Text(
                'Your progress is saved automatically.\nYou can resume this round from the home screen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.secondaryText,
                  fontSize: (sw * 0.036).clamp(13.0, 15.0),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Save & Exit
              GestureDetector(
                onTap: () async {
                  // currentHole is already persisted on every advance.
                  // If this is a group round and the current user is the host,
                  // cancel the session so invitees see it's no longer active.
                  if (widget.sessionId != null) {
                    try {
                      final session = await GroupRoundService.fetchSession(
                          widget.sessionId!);
                      if (session != null &&
                          session.hostUid ==
                              FirebaseAuth.instance.currentUser?.uid) {
                        await GroupRoundService.cancelSession(
                            widget.sessionId!);
                      }
                    } catch (_) {}
                  }
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  Navigator.of(context)
                      ..pop() // dialog
                      ..pop(); // scorecard screen
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
                      borderRadius: BorderRadius.circular(28),
                    ),
                    shadows: [
                      BoxShadow(
                        color: const Color(0xFF5A9E1F).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('Save & Exit',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.white,
                            fontSize: (sw * 0.040).clamp(14.0, 16.0),
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Keep Playing + Abandon row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 46,
                        decoration: ShapeDecoration(
                          color: c.cardBg,
                          shape: SuperellipseShape(
                            borderRadius: BorderRadius.circular(28),
                            side: BorderSide(color: c.cardBorder),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text('Keep Playing',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: c.primaryText,
                              fontSize: (sw * 0.036).clamp(13.0, 15.0),
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        await RoundService.abandonRound(widget.roundId);
                        // Cancel the group session if the host abandons
                        if (widget.sessionId != null) {
                          try {
                            final session = await GroupRoundService
                                .fetchSession(widget.sessionId!);
                            if (session != null &&
                                session.hostUid ==
                                    FirebaseAuth.instance.currentUser?.uid) {
                              await GroupRoundService.cancelSession(
                                  widget.sessionId!);
                            }
                          } catch (_) {}
                        }
                        if (mounted) {
                          Navigator.of(context)
                            ..pop()
                            ..pop();
                        }
                      },
                      child: Container(
                        height: 46,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFE53935).withValues(alpha: 0.10),
                          shape: SuperellipseShape(
                            borderRadius: BorderRadius.circular(28),
                            side: BorderSide(
                              color: const Color(0xFFE53935).withValues(alpha: 0.30),
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text('Abandon',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: const Color(0xFFE53935),
                              fontSize: (sw * 0.036).clamp(13.0, 15.0),
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color _scoreColor(int diff) {
    if (diff <= -2) return const Color(0xFFFFD700); // Eagle+
    if (diff == -1) return const Color(0xFF4CAF82); // Birdie
    if (diff == 0)  return const Color(0xFF64B5F6); // Par
    if (diff == 1)  return const Color(0xFFFFB74D); // Bogey
    return const Color(0xFFE53935);                 // Double+
  }

  String _scoreLabel(int diff) {
    if (diff <= -2) return diff == -2 ? 'Eagle' : 'Albatross';
    if (diff == -1) return 'Birdie';
    if (diff == 0)  return 'Par';
    if (diff == 1)  return 'Bogey';
    if (diff == 2)  return 'Double';
    return '+$diff';
  }
}

class _WeatherChip extends StatelessWidget {
  final WeatherNow weather;
  final double label;
  const _WeatherChip({required this.weather, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: ShapeDecoration(
        color: c.iconContainerBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.cardBorder),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.thermostat_rounded, color: c.secondaryText, size: label),
          const SizedBox(width: 2),
          Text(weather.tempLabel,
              style: TextStyle(color: c.secondaryText, fontSize: label * 0.88)),
          const SizedBox(width: 6),
          Icon(Icons.air_rounded, color: c.secondaryText, size: label),
          const SizedBox(width: 2),
          Text(weather.windLabel,
              style: TextStyle(color: c.secondaryText, fontSize: label * 0.88)),
        ],
      ),
    );
  }
}

// ── _ScoreStepperWidget — full-width split tap stepper ───────────────────────

class _ScoreStepperWidget extends StatefulWidget {
  final int value;
  final Color scoreColor;
  final Animation<double> bounceAnim;
  final AnimationController bounceCtrl;
  final AppColors c;
  final double sw;
  final double sh;
  final void Function(int delta) onStep;

  const _ScoreStepperWidget({
    required this.value,
    required this.scoreColor,
    required this.bounceAnim,
    required this.bounceCtrl,
    required this.c,
    required this.sw,
    required this.sh,
    required this.onStep,
  });

  @override
  State<_ScoreStepperWidget> createState() => _ScoreStepperWidgetState();
}

class _ScoreStepperWidgetState extends State<_ScoreStepperWidget> {
  Timer? _repeatTimer;

  void _startRepeat(int delta) {
    _repeatTimer?.cancel();
    _step(delta);
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 150), (_) => _step(delta));
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  void _step(int delta) {
    HapticFeedback.lightImpact();
    widget.onStep(delta);
    widget.bounceCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c  = widget.c;
    final sw = widget.sw;
    final sh = widget.sh;

    return Container(
      height: (sh * 0.14).clamp(100.0, 130.0),
      decoration: ShapeDecoration(
        color: c.fieldBg,
        shape: SuperellipseShape(borderRadius: BorderRadius.circular(24)),
        shadows: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8, offset: const Offset(0, 3),
        )],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap:             () => _step(-1),
              onLongPressStart:  (_) => _startRepeat(-1),
              onLongPressEnd:    (_) => _stopRepeat(),
              onLongPressCancel: _stopRepeat,
              child: Container(
                color: Colors.transparent,
                child: Center(child: Icon(Icons.remove_rounded,
                    color: c.secondaryText,
                    size: (sw * 0.07).clamp(24.0, 32.0))),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: widget.bounceAnim,
            builder: (_, child) => Transform.scale(
              scale: widget.bounceAnim.value, child: child),
            child: SizedBox(
              width: (sw * 0.22).clamp(75.0, 95.0),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${widget.value}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color:      widget.scoreColor,
                      fontSize:   (sw * 0.18).clamp(68.0, 88.0),
                      fontWeight: FontWeight.w800,
                      height:     1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap:             () => _step(1),
              onLongPressStart:  (_) => _startRepeat(1),
              onLongPressEnd:    (_) => _stopRepeat(),
              onLongPressCancel: _stopRepeat,
              child: Container(
                color: Colors.transparent,
                child: Center(child: Icon(Icons.add_rounded,
                    color: c.secondaryText,
                    size: (sw * 0.07).clamp(24.0, 32.0))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _BigToggle — glove-friendly full-width toggle card ───────────────────────

class _BigToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final AppColors c;
  final double sw;
  final double sh;
  final VoidCallback onTap;

  const _BigToggle({
    required this.label,
    required this.icon,
    required this.value,
    required this.c,
    required this.sw,
    required this.sh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final minH = (sh * 0.088).clamp(60.0, 72.0);
    final on   = value;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: BoxConstraints(minHeight: minH),
        padding: EdgeInsets.symmetric(
          horizontal: (sw * 0.045).clamp(14.0, 20.0),
          vertical:   12,
        ),
        decoration: ShapeDecoration(
          color: on ? c.accentBg.withValues(alpha: 0.6) : c.fieldBg,
          shape: SuperellipseShape(borderRadius: BorderRadius.circular(20)),
          shadows: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4, offset: const Offset(0, 2),
          )],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36, height: 36,
              decoration: BoxDecoration(
                color:        on ? c.accentBorder : c.fieldBorder.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: on ? c.accent : c.tertiaryText, size: 20),
            ),
            SizedBox(width: (sw * 0.03).clamp(10.0, 14.0)),
            Expanded(
              child: Text(label, style: TextStyle(
                color:      on ? c.primaryText : c.secondaryText,
                fontSize:   (sw * 0.034).clamp(12.0, 15.0),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              )),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:        on ? c.accentBorder : c.fieldBorder.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(on ? 'ON' : 'OFF', style: TextStyle(
                color:      on ? c.accent : Colors.white,
                fontSize:   11.0,
                fontWeight: FontWeight.w800,
              )),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _HoleMiniMap — simple par-based hole shape ────────────────────────────────

class _HoleMiniMap extends StatelessWidget {
  final int par;
  final double size;
  final AppColors c;
  const _HoleMiniMap({required this.par, required this.size, required this.c});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  size * 0.72,
      height: size,
      child:  CustomPaint(painter: _HolePainter(par: par, c: c)),
    );
  }
}

class _HolePainter extends CustomPainter {
  final int par;
  final AppColors c;
  const _HolePainter({required this.par, required this.c});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fairwayPaint = Paint()
      ..color = c.accentBg
      ..style = PaintingStyle.fill;
    final greenPaint = Paint()
      ..color = c.accent
      ..style = PaintingStyle.fill;
    final teePaint = Paint()
      ..color = c.secondaryText.withValues(alpha: 0.50)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fw = w * 0.40;

    if (par <= 3) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH((w - fw) / 2, h * 0.08, fw, h * 0.72),
        Radius.circular(fw / 2),
      );
      path.addRRect(rect);
    } else if (par == 4) {
      path.moveTo(w * 0.30, h * 0.80);
      path.lineTo(w * 0.30, h * 0.35);
      path.quadraticBezierTo(w * 0.30, h * 0.15, w * 0.50, h * 0.12);
      path.lineTo(w * 0.80, h * 0.12);
      path.lineTo(w * 0.80, h * 0.28);
      path.lineTo(w * 0.50, h * 0.28);
      path.quadraticBezierTo(w * 0.44, h * 0.28, w * 0.44, h * 0.35);
      path.lineTo(w * 0.44, h * 0.80);
      path.close();
    } else {
      path.moveTo(w * 0.26, h * 0.82);
      path.lineTo(w * 0.26, h * 0.56);
      path.cubicTo(
        w * 0.26, h * 0.42,
        w * 0.60, h * 0.48,
        w * 0.60, h * 0.34,
      );
      path.lineTo(w * 0.60, h * 0.10);
      path.lineTo(w * 0.74, h * 0.10);
      path.lineTo(w * 0.74, h * 0.34);
      path.cubicTo(
        w * 0.74, h * 0.52,
        w * 0.40, h * 0.46,
        w * 0.40, h * 0.60,
      );
      path.lineTo(w * 0.40, h * 0.82);
      path.close();
    }

    canvas.drawPath(path, fairwayPaint);

    final greenCenter = par <= 3
        ? Offset(w / 2, h * 0.12)
        : par == 4
            ? Offset(w * 0.80, h * 0.20)
            : Offset(w * 0.67, h * 0.10);
    canvas.drawCircle(greenCenter, w * 0.14, greenPaint);

    final teeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(
          par <= 3 ? w / 2 : w * 0.37,
          h * 0.87,
        ),
        width:  w * 0.26,
        height: h * 0.07,
      ),
      Radius.circular(3),
    );
    canvas.drawRRect(teeRect, teePaint);
  }

  @override
  bool shouldRepaint(_HolePainter old) => old.par != par;
}

// ── _SuperellipseClipper ─────────────────────────────────────────────────────

class _SuperellipseClipper extends CustomClipper<Path> {
  final double radius;
  const _SuperellipseClipper({required this.radius});

  @override
  Path getClip(Size size) {
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius * 0.72)));
  }

  @override
  bool shouldReclip(_SuperellipseClipper old) => old.radius != radius;
}

// ── _RadialExpandClipper ──────────────────────────────────────────────────────

class _RadialExpandClipper extends CustomClipper<Rect> {
  final double progress;
  const _RadialExpandClipper({required this.progress});

  @override
  Rect getClip(Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.sqrt(c.dx * c.dx + c.dy * c.dy) * progress;
    return Rect.fromCircle(center: c, radius: r);
  }

  @override
  bool shouldReclip(_RadialExpandClipper o) => o.progress != progress;
}
