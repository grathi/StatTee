import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/pressure_profile.dart';
import '../models/pressure_narrative.dart';
import '../services/ai_pressure_narrative_service.dart';
import '../theme/app_theme.dart';
import '../utils/l10n_extension.dart';

class PressureScoreScreen extends StatefulWidget {
  final PressureProfile profile;
  final PressureNarrative? narrative;

  const PressureScoreScreen({
    super.key,
    required this.profile,
    this.narrative,
  });

  @override
  State<PressureScoreScreen> createState() => _PressureScoreScreenState();
}

class _PressureScoreScreenState extends State<PressureScoreScreen> {
  PressureNarrative? _narrative;
  bool _loadingNarrative = false;

  @override
  void initState() {
    super.initState();
    _narrative = widget.narrative;
    if (_narrative == null) _fetchNarrative();
  }

  Future<void> _fetchNarrative() async {
    setState(() => _loadingNarrative = true);
    final n = await AIPressureNarrativeService.generate(widget.profile);
    if (mounted) setState(() { _narrative = n; _loadingNarrative = false; });
  }

  @override
  Widget build(BuildContext context) {
    final c  = AppColors.of(context);
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final hPad = (sw * 0.055).clamp(18.0, 28.0);

    final score      = widget.profile.compositeScore;
    final scoreColor = score >= 75
        ? const Color(0xFF5A9E1F)
        : score >= 50
            ? const Color(0xFFFFB74D)
            : const Color(0xFFE53935);

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
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App bar ────────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.primaryText, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  context.l10n.statsPressureScore,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: c.primaryText,
                    fontSize: (sw * 0.046).clamp(16.0, 20.0),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                centerTitle: true,
                pinned: true,
              ),

              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, sh * 0.02, hPad, sh * 0.14),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Score hero ─────────────────────────────────────
                    _buildScoreHero(context, c, sw, sh, score, scoreColor),
                    SizedBox(height: sh * 0.022),

                    // ── 5 Metric rows ──────────────────────────────────
                    _buildMetricsCard(context, c, sw, sh),
                    SizedBox(height: sh * 0.022),

                    // ── Top Drill ──────────────────────────────────────
                    if (_narrative != null && _narrative!.topDrill.isNotEmpty)
                      _buildTopDrillCard(context, c, sw, sh),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Score hero card ────────────────────────────────────────────────────────
  Widget _buildScoreHero(BuildContext context, AppColors c, double sw, double sh,
      int score, Color scoreColor) {
    final body  = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);

    return Container(
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          colors: c.cardGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(48),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      padding: EdgeInsets.all((sw * 0.055).clamp(18.0, 24.0)),
      child: Column(
        children: [
          // Score ring + number
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: (sw * 0.28).clamp(95.0, 120.0),
                height: (sw * 0.28).clamp(95.0, 120.0),
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: c.iconContainerBorder.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: scoreColor,
                      fontSize: (sw * 0.085).clamp(30.0, 42.0),
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    context.l10n.statsPressureResilience,
                    style: TextStyle(color: c.tertiaryText, fontSize: label * 0.85),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: sh * 0.016),
          // AI headline
          Skeletonizer(
            enabled: _loadingNarrative,
            child: Text(
              _narrative?.headline ?? (_loadingNarrative ? 'Analyzing pressure patterns...' : ''),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.secondaryText,
                fontSize: body,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          if (_narrative?.overallInsight != null && _narrative!.overallInsight.isNotEmpty) ...[
            SizedBox(height: sh * 0.012),
            Skeletonizer(
              enabled: _loadingNarrative,
              child: Text(
                _narrative!.overallInsight,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.tertiaryText, fontSize: label),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 5 Metric rows card ─────────────────────────────────────────────────────
  Widget _buildMetricsCard(BuildContext context, AppColors c, double sw, double sh) {
    final body  = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);

    // Max delta for bar scaling (excluding three_putt which uses ratio)
    final scoreMetrics = widget.profile.metrics
        .where((m) => m.id != kMetricThreePutt)
        .toList();
    final maxDelta = scoreMetrics.isEmpty
        ? 1.0
        : scoreMetrics.map((m) => m.delta.abs()).fold(0.0, (a, b) => a > b ? a : b);
    final barScale = maxDelta == 0 ? 1.0 : maxDelta;

    const metricOrder = [
      kMetricOpeningHole,
      kMetricBirdieHangover,
      kMetricBackNine,
      kMetricFinishingStretch,
      kMetricThreePutt,
    ];

    String metricLabelFor(String id) {
      switch (id) {
        case kMetricOpeningHole:       return context.l10n.statsPressureOpeningHole;
        case kMetricBirdieHangover:    return context.l10n.statsPressureBirdieHangover;
        case kMetricBackNine:          return context.l10n.statsPressureBackNine;
        case kMetricFinishingStretch:  return context.l10n.statsPressureFinishingStretch;
        case kMetricThreePutt:         return context.l10n.statsPressureThreePutt;
        default: return id;
      }
    }

    return Container(
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          colors: c.cardGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(48),
          side: BorderSide(color: c.cardBorder),
        ),
        shadows: c.cardShadow,
      ),
      padding: EdgeInsets.all((sw * 0.055).clamp(18.0, 24.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pressure Patterns',
            style: TextStyle(
              fontFamily: 'Nunito',
              color: c.primaryText,
              fontSize: body,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: sh * 0.018),
          for (final id in metricOrder) ...[
            _buildMetricRow(
              context, c, sw, sh, label,
              metric: widget.profile.metricById(id),
              metricId: id,
              metricLabel: metricLabelFor(id),
              barScale: id == kMetricThreePutt ? 2.5 : barScale,
              isRatio: id == kMetricThreePutt,
            ),
            if (id != metricOrder.last) Divider(color: c.cardBorder.withValues(alpha: 0.5), height: sh * 0.030),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    AppColors c,
    double sw,
    double sh,
    double label, {
    required PressureMetric? metric,
    required String metricId,
    required String metricLabel,
    required double barScale,
    required bool isRatio,
  }) {
    final insight = _narrative?.insightFor(metricId);
    final hasData = metric != null && metric.sampleSize >= 3;
    final problem = metric?.isSignificant ?? false;
    final delta   = metric?.delta ?? 0.0;

    // Bar direction: positive delta = worse = red bar right; negative = green left
    final barFraction = hasData ? (delta.abs() / barScale).clamp(0.0, 1.0) : 0.0;
    final isPositive  = delta >= 0;
    final barColor    = problem
        ? const Color(0xFFE53935)
        : const Color(0xFF5A9E1F);
    final maxBarWidth = sw * 0.30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name + indicator dot + delta value
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: problem
                    ? const Color(0xFFE53935)
                    : c.tertiaryText.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                metricLabel,
                style: TextStyle(
                  color: c.primaryText,
                  fontSize: label,
                  fontWeight: problem ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            // Delta bar
            if (hasData)
              SizedBox(
                width: maxBarWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: (!isPositive)
                            ? AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                width: barFraction * maxBarWidth * 0.5,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5A9E1F),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(3),
                                    bottomLeft: Radius.circular(3),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    Container(width: 1.5, height: 14, color: c.cardBorder),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: isPositive
                            ? AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                width: barFraction * maxBarWidth * 0.5,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(3),
                                    bottomRight: Radius.circular(3),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            // Delta label
            SizedBox(
              width: (sw * 0.14).clamp(46.0, 60.0),
              child: Text(
                hasData
                    ? isRatio
                        ? '${delta.toStringAsFixed(1)}×'
                        : '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(2)}'
                    : context.l10n.statsPressureInsufficientData,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: hasData ? (problem ? const Color(0xFFE53935) : const Color(0xFF5A9E1F)) : c.tertiaryText,
                  fontSize: label * (hasData ? 1.0 : 0.85),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        // AI insight + drill
        if (insight != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Skeletonizer(
              enabled: _loadingNarrative,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.insight,
                    style: TextStyle(color: c.secondaryText, fontSize: label * 0.9),
                  ),
                  if (insight.drill.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.fitness_center_rounded,
                            color: c.accent, size: label),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            insight.drill,
                            style: TextStyle(
                              color: c.accent,
                              fontSize: label * 0.9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Top Drill card ─────────────────────────────────────────────────────────
  Widget _buildTopDrillCard(BuildContext context, AppColors c, double sw, double sh) {
    final body  = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);

    return Container(
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A08), Color(0xFF2E5C10), Color(0xFF3D7A14)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(48),
          side: const BorderSide(color: Color(0xFF5A9E1F)),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x405A9E1F),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all((sw * 0.055).clamp(18.0, 24.0)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: (sw * 0.10).clamp(36.0, 44.0),
            height: (sw * 0.10).clamp(36.0, 44.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.fitness_center_rounded,
                color: Colors.white, size: (sw * 0.048).clamp(16.0, 22.0)),
          ),
          SizedBox(width: (sw * 0.035).clamp(10.0, 16.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.statsPressureTopDrill,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontSize: body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _narrative!.topDrill,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: label,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
