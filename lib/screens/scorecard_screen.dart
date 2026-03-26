import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import 'dart:async';
import '../models/hole_score.dart';
import '../services/round_service.dart';
import '../services/notification_service.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tip_banner.dart';
import '../services/onboarding_service.dart';
import 'round_summary_screen.dart';

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
  });

  @override
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen>
    with SingleTickerProviderStateMixin {
  int _currentHole = 1;
  int _par   = 4;
  int _score = 4;
  int _putts = 2;
  bool _fairwayHit = true;
  bool _gir        = false;
  String? _club;
  bool _isSaving   = false;

  // GPS pin tracking
  Position? _userPos;
  Position? _pinPos;
  StreamSubscription<Position>? _posSub;
  bool _weatherFetched = false;
  WeatherNow? _liveWeather;

  static const _clubs = [
    'Driver','3W','5W','4H','3I','4I','5I','6I','7I','8I','9I',
    'PW','GW','SW','LW','Putter',
  ];

  // Completed hole scores saved so far
  final List<HoleScore> _saved = [];

  // Track when the round started to compute duration for calorie estimate
  final DateTime _roundStartTime = DateTime.now();

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

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
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    // Pre-populate any scores already saved (resume path)
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
    _posSub?.cancel();
    super.dispose();
  }

  void _resetForHole(int hole) {
    // Check if we already have a saved score for this hole (editing)
    final existing = _saved.where((h) => h.hole == hole).firstOrNull;
    setState(() {
      _currentHole = hole;
      _par         = existing?.par   ?? 4;
      _score       = existing?.score ?? 4;
      _putts       = existing?.putts ?? 2;
      _fairwayHit  = existing?.fairwayHit ?? true;
      _gir         = existing?.gir        ?? false;
      _club        = existing?.club;
      _pinPos      = null; // reset pin for each hole
    });
    _animCtrl
      ..reset()
      ..forward();
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
      club:       _club,
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
        await _completeRound();
      } else {
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

    if (!mounted) return;
    widget.onComplete?.call(widget.roundId);
    _showRoundSummary();
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
      MaterialPageRoute(
        builder: (_) => RoundSummaryScreen(
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
          carriedBag:      true,  // default: walking with bag
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: c.bgGradient,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
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
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: _hPad),
                    child: Column(
                      children: [
                        SizedBox(height: _sh * 0.022),
                        _buildHoleCard(c),
                        SizedBox(height: _sh * 0.022),
                        if (_saved.isNotEmpty) _buildPreviousHoles(c),
                        SizedBox(height: _sh * 0.02),
                      ],
                    ),
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
                color: c.iconContainerBg,
                border: Border.all(color: c.iconContainerBorder),
              ),
              child: Icon(Icons.close_rounded,
                  color: c.iconColor, size: _body * 1.1),
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
                if (_liveWeather != null) ...[
                  const SizedBox(height: 2),
                  _WeatherChip(weather: _liveWeather!, label: _label),
                ],
              ],
            ),
          ),
          // Running total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: ShapeDecoration(
              color: _runningDiff <= 0 ? c.accentBg : const Color(0xFFE53935).withValues(alpha: 0.12),
              shape: SuperellipseShape(
                borderRadius: BorderRadius.circular(40),
                side: BorderSide(
                  color: _runningDiff <= 0 ? c.accentBorder : const Color(0xFFE53935).withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Text(
              _runningDiffLabel,
              style: TextStyle(fontFamily: 'Nunito',
                color: _runningDiff <= 0 ? c.accent : const Color(0xFFE53935),
                fontSize: _body,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
          final isDone   = _saved.any((h) => h.hole == hole);
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
                          ? c.accent.withValues(alpha: 0.5)
                          : c.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Hole entry card ────────────────────────────────────────────────────────
  Widget _buildHoleCard(AppColors c) {
    return Container(
      decoration: ShapeDecoration(
        color: c.cardBg,
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow
            .map((s) => BoxShadow(
                  color: s.color,
                  blurRadius: s.blurRadius,
                  offset: s.offset,
                  spreadRadius: s.spreadRadius,
                ))
            .toList(),
      ),
      padding: EdgeInsets.all((_sw * 0.06).clamp(20.0, 28.0)),
      child: Column(
        children: [
          // Hole number big display
          _rowLabel(c, 'Hole'),
          SizedBox(height: _sh * 0.004),
          Center(
            child: Text(
              '$_currentHole',
              style: TextStyle(fontFamily: 'Nunito',
                color: c.primaryText,
                fontSize: (_sw * 0.16).clamp(54.0, 72.0),
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ),
          SizedBox(height: _sh * 0.024),
          // Par selector
          _rowLabel(c, 'Par'),
          SizedBox(height: _sh * 0.010),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [3, 4, 5].map((p) {
              final sel = _par == p;
              return GestureDetector(
                onTap: () => setState(() {
                  _par = p;
                  _score = p; // default score to par
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: (_sw * 0.17).clamp(56.0, 72.0),
                  height: (_sw * 0.12).clamp(40.0, 52.0),
                  decoration: ShapeDecoration(
                    color: sel ? c.accent : c.fieldBg,
                    shape: SuperellipseShape(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: sel ? c.accent : c.fieldBorder,
                        width: sel ? 2 : 1,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$p',
                      style: TextStyle(fontFamily: 'Nunito',
                        color: sel ? Colors.white : c.primaryText,
                        fontSize: (_sw * 0.052).clamp(18.0, 22.0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: _sh * 0.026),
          // Score tiles
          _rowLabel(c, 'Score'),
          SizedBox(height: _sh * 0.010),
          _numberTiles(
            context: context,
            values: List.generate(12, (i) => i + 1),
            selected: _score,
            par: _par,
            onSelect: (v) => setState(() => _score = v),
            c: c,
            sw: _sw,
            label: _label,
          ),
          SizedBox(height: _sh * 0.022),
          // Putts tiles
          _rowLabel(c, 'Putts'),
          SizedBox(height: _sh * 0.010),
          _numberTiles(
            context: context,
            values: List.generate(9, (i) => i),
            selected: _putts,
            par: null,
            onSelect: (v) => setState(() => _putts = v),
            c: c,
            sw: _sw,
            label: _label,
          ),
          SizedBox(height: _sh * 0.026),
          // Toggles
          Row(
            children: [
              if (_par >= 4) ...[
                Expanded(child: _buildToggle(c, 'Fairway Hit', _fairwayHit,
                    Icons.straighten_rounded,
                    (v) => setState(() => _fairwayHit = v))),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _buildToggle(c, 'Green in Reg.', _gir,
                    Icons.flag_rounded,
                    (v) => setState(() => _gir = v)),
              ),
            ],
          ),
          SizedBox(height: _sh * 0.022),
          // GPS pin distance
          if (_userPos != null) _buildGpsRow(c),
          if (_userPos != null) SizedBox(height: _sh * 0.022),
          // Club selector
          _rowLabel(c, 'Club Used'),
          SizedBox(height: _sh * 0.010),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _clubs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final club = _clubs[i];
                final selected = _club == club;
                return GestureDetector(
                  onTap: () => setState(() => _club = selected ? null : club),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? c.accent : c.fieldBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? c.accent : c.fieldBorder),
                    ),
                    child: Text(
                      club,
                      style: TextStyle(
                        color: selected ? Colors.white : c.secondaryText,
                        fontSize: _label,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── GPS Pin distance ────────────────────────────────────────────────────────
  int? get _pinDistanceYards {
    if (_userPos == null || _pinPos == null) return null;
    final meters = Geolocator.distanceBetween(
      _userPos!.latitude, _userPos!.longitude,
      _pinPos!.latitude, _pinPos!.longitude,
    );
    return (meters * 1.09361).round();
  }

  Color _distanceColor(int yards) {
    if (yards <= 100) return const Color(0xFF4CAF50);   // green — short
    if (yards <= 175) return const Color(0xFFFFB74D);   // amber — mid
    return const Color(0xFFE53935);                      // red — long
  }

  Widget _buildGpsRow(AppColors c) {
    final yards = _pinDistanceYards;
    return Row(
      children: [
        if (yards == null) ...[
          // No pin set yet
          GestureDetector(
            onTap: () => setState(() => _pinPos = _userPos),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: ShapeDecoration(
                color: c.accentBg,
                shape: SuperellipseShape(
                  borderRadius: BorderRadius.circular(40),
                  side: BorderSide(color: c.accentBorder),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.push_pin_rounded, color: c.accent, size: _label * 1.1),
                  const SizedBox(width: 6),
                  Text('Set Pin',
                      style: TextStyle(
                          color: c.accent,
                          fontSize: _label,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ] else ...[
          // Pin set — show live distance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: ShapeDecoration(
              color: _distanceColor(yards).withValues(alpha: 0.12),
              shape: SuperellipseShape(
                borderRadius: BorderRadius.circular(40),
                side: BorderSide(
                    color: _distanceColor(yards).withValues(alpha: 0.4)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.push_pin_rounded,
                    color: _distanceColor(yards), size: _label * 1.1),
                const SizedBox(width: 6),
                Text('$yards yds',
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        color: _distanceColor(yards),
                        fontSize: _label * 1.1,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _pinPos = null),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: c.fieldBg,
                shape: BoxShape.circle,
                border: Border.all(color: c.fieldBorder),
              ),
              child: Icon(Icons.close_rounded,
                  color: c.tertiaryText, size: _label),
            ),
          ),
        ],
      ],
    );
  }

  Widget _rowLabel(AppColors c, String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            color: c.secondaryText,
            fontSize: _label,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _buildToggle(AppColors c, String label, bool value, IconData icon,
      void Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
            horizontal: (_sw * 0.032).clamp(10.0, 16.0),
            vertical: (_sh * 0.014).clamp(10.0, 14.0)),
        decoration: ShapeDecoration(
          color: value ? c.accentBg : c.fieldBg,
          shape: SuperellipseShape(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
                color: value ? c.accentBorder : c.fieldBorder),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: value ? c.accent : c.tertiaryText,
                size: _body * 1.1),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: value ? c.accent : c.secondaryText,
                  fontSize: _label,
                  fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
      if (d == -1) return const Color(0xFF4CAF50);       // birdie
      if (d == 0)  return const Color(0xFF5A9E1F);       // par
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
          'Scorecard',
          style: TextStyle(fontFamily: 'Nunito',
              color: c.primaryText,
              fontSize: _body,
              fontWeight: FontWeight.w700),
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
                              color: c.secondaryText, fontSize: _label)),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
          _hPad, _sh * 0.012, _hPad, _sh * 0.030),
      child: GestureDetector(
        onTap: _isSaving ? null : _saveAndAdvance,
        child: Opacity(
          opacity: _isSaving ? 0.5 : 1.0,
          child: Container(
            width: double.infinity,
            height: (_sh * 0.072).clamp(52.0, 64.0),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: c.accent,
              shape: SuperellipseShape(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white)),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLastHole ? 'Complete Round' : 'Next Hole',
                        style: TextStyle(fontFamily: 'Nunito',
                          fontSize: (_sw * 0.046).clamp(16.0, 20.0),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isLastHole
                            ? Icons.flag_rounded
                            : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: _body * 1.2,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── Abandon dialog ─────────────────────────────────────────────────────────
  void _showAbandonDialog(AppColors c) {
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
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  )),
              const SizedBox(height: 8),
              Text(
                'Your progress is saved automatically.\nYou can resume this round from the home screen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.secondaryText,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Save & Exit
              GestureDetector(
                onTap: () {
                  // currentHole is already persisted on every advance.
                  // Just close the dialog and pop back to home.
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
                            fontSize: 15,
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
                              fontSize: 14,
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
                        child: const Text('Abandon',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: Color(0xFFE53935),
                              fontSize: 14,
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
