import 'package:flutter/material.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/golf_dna.dart';
import '../theme/app_theme.dart';

// ── Palette constants ─────────────────────────────────────────────────────────
const _kNavy    = Color(0xFF0C1B2E);
const _kNavyMid = Color(0xFF1A3A52);
const _kGreen   = Color(0xFF5A9E1F);
const _kGreenLt = Color(0xFF8FD44E);
const _kGold    = Color(0xFFFFB300);

// ── GolfDNACard ───────────────────────────────────────────────────────────────

class GolfDNACard extends StatelessWidget {
  final GolfDNA dna;
  const GolfDNACard({super.key, required this.dna});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kGreen, _kNavyMid, _kNavy],
          stops: [0.0, 0.55, 1.0],
        ),
        shape: SuperellipseShape(borderRadius: BorderRadius.circular(48)),
        shadows: [
          BoxShadow(
            color: _kGreen.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _kNavy.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative radial glow behind the icon
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kGreenLt.withValues(alpha: 0.10),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all((sw * 0.055).clamp(16.0, 22.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DNA icon badge
                    Container(
                      width:  (sw * 0.115).clamp(40.0, 48.0),
                      height: (sw * 0.115).clamp(40.0, 48.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                    ),
                      child: Icon(Icons.biotech_rounded,
                          color: Colors.white, size: (sw * 0.055).clamp(18.0, 22.0)),
                    ),
                    SizedBox(width: (sw * 0.035).clamp(10.0, 14.0)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GOLF DNA',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: (sw * 0.026).clamp(10.0, 12.0),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dna.playerType,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: Colors.white,
                              fontSize: (sw * 0.056).clamp(20.0, 24.0),
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Player type badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: (sw * 0.025).clamp(8.0, 10.0),
                        vertical: (sw * 0.012).clamp(4.0, 5.0),
                      ),
                      decoration: BoxDecoration(
                        color: _kGold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kGold.withValues(alpha: 0.45)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded,
                              color: _kGold, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            'PRO ANALYSIS',
                            style: TextStyle(
                              color: _kGold,
                              fontSize: (sw * 0.022).clamp(9.0, 11.0),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: (sw * 0.04).clamp(12.0, 16.0)),
                // Divider
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
                SizedBox(height: (sw * 0.04).clamp(12.0, 16.0)),

                // Summary
                Text(
                  dna.summary,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: (sw * 0.033).clamp(12.0, 14.5),
                    height: 1.55,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                SizedBox(height: (sw * 0.045).clamp(14.0, 18.0)),
                // Mini stat pills row
                Row(
                  children: [
                    _StatPill(
                        label: 'Power',
                        value: dna.drivingPower,
                        color: _kGreenLt),
                    const SizedBox(width: 8),
                    _StatPill(
                        label: 'Accuracy',
                        value: dna.accuracy,
                        color: const Color(0xFF42B0FF)),
                    const SizedBox(width: 8),
                    _StatPill(
                        label: 'Putting',
                        value: dna.putting,
                        color: _kGold),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (sw * 0.025).clamp(8.0, 10.0),
        vertical: (sw * 0.012).clamp(4.0, 5.0),
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: (sw * 0.032).clamp(11.0, 13.0),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: (sw * 0.026).clamp(9.0, 11.0),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── DNATraitBar ───────────────────────────────────────────────────────────────

class DNATraitBar extends StatefulWidget {
  final String label;
  final int value; // 0–100
  final Color color;
  final Duration delay;

  const DNATraitBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.delay = Duration.zero,
  });

  @override
  State<DNATraitBar> createState() => _DNATraitBarState();
}

class _DNATraitBarState extends State<DNATraitBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _trackColor {
    if (widget.value >= 70) return widget.color;
    if (widget.value >= 45) return widget.color.withValues(alpha: 0.75);
    return widget.color.withValues(alpha: 0.50);
  }

  String get _grade {
    if (widget.value >= 85) return 'S';
    if (widget.value >= 70) return 'A';
    if (widget.value >= 55) return 'B';
    if (widget.value >= 40) return 'C';
    return 'D';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final sw = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          // Label
          SizedBox(
            width: sw * 0.26,
            child: Text(
              widget.label,
              style: TextStyle(
                color: c.primaryText,
                fontSize: (sw * 0.032).clamp(11.5, 14.0),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Bar
          Expanded(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      // Track
                      Container(
                        height: 9,
                        color: c.cardBorder.withValues(alpha: 0.5),
                      ),
                      // Fill
                      FractionallySizedBox(
                        widthFactor:
                            (widget.value / 100.0) * _anim.value,
                        child: Container(
                          height: 9,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _trackColor.withValues(alpha: 0.70),
                                _trackColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          // Value number
          SizedBox(
            width: 28,
            child: Text(
              '${widget.value}',
              textAlign: TextAlign.end,
              style: TextStyle(
                color: _trackColor,
                fontSize: (sw * 0.032).clamp(11.5, 13.5),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Grade badge
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _trackColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _grade,
              style: TextStyle(
                color: _trackColor,
                fontSize: (sw * 0.026).clamp(9.0, 11.0),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── StrengthWeaknessCard ──────────────────────────────────────────────────────

class StrengthWeaknessCard extends StatelessWidget {
  final List<String> strengths;
  final List<String> weaknesses;
  const StrengthWeaknessCard({
    super.key,
    required this.strengths,
    required this.weaknesses,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final sw = MediaQuery.of(context).size.width;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(
              (sw * 0.045).clamp(14.0, 18.0),
              (sw * 0.04).clamp(12.0, 16.0),
              (sw * 0.045).clamp(14.0, 18.0),
              0,
            ),
            child: Row(
              children: [
                Container(
                  width:  (sw * 0.09).clamp(32.0, 38.0),
                  height: (sw * 0.09).clamp(32.0, 38.0),
                  decoration: BoxDecoration(
                    color: c.accentBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.accentBorder),
                  ),
                  child: Icon(Icons.balance_rounded,
                      color: c.accent, size: (sw * 0.045).clamp(15.0, 18.0)),
                ),
                SizedBox(width: (sw * 0.025).clamp(8.0, 10.0)),
                Text(
                  'Strengths & Weaknesses',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: c.primaryText,
                    fontSize: (sw * 0.038).clamp(13.5, 16.0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: c.divider),
          const SizedBox(height: 4),
          // Strengths
          _SwSection(
            items: strengths,
            isStrength: true,
            c: c,
            sw: sw,
          ),
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: (sw * 0.045).clamp(14.0, 18.0),
            ),
            height: 1,
            color: c.divider,
          ),
          // Weaknesses
          _SwSection(
            items: weaknesses,
            isStrength: false,
            c: c,
            sw: sw,
          ),
        ],
      ),
    );
  }
}

class _SwSection extends StatelessWidget {
  final List<String> items;
  final bool isStrength;
  final AppColors c;
  final double sw;

  const _SwSection({
    required this.items,
    required this.isStrength,
    required this.c,
    required this.sw,
  });

  @override
  Widget build(BuildContext context) {
    final color = isStrength ? _kGreen : const Color(0xFFEF4444);
    final bg = color.withValues(alpha: 0.07);
    final label = isStrength ? 'STRENGTHS' : 'WEAKNESSES';
    final icon = isStrength
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        (sw * 0.045).clamp(14.0, 18.0),
        (sw * 0.03).clamp(10.0, 12.0),
        (sw * 0.045).clamp(14.0, 18.0),
        (sw * 0.03).clamp(10.0, 12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: (sw * 0.024).clamp(9.0, 11.0),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: (sw * 0.03).clamp(10.0, 12.0),
                  vertical: (sw * 0.022).clamp(7.0, 9.0),
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: c.primaryText,
                          fontSize: (sw * 0.031).clamp(11.0, 13.5),
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── DNATrendCard ──────────────────────────────────────────────────────────────

class DNATrendCard extends StatelessWidget {
  final List<String> trends;
  const DNATrendCard({super.key, required this.trends});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final sw = MediaQuery.of(context).size.width;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(
              (sw * 0.045).clamp(14.0, 18.0),
              (sw * 0.04).clamp(12.0, 16.0),
              (sw * 0.045).clamp(14.0, 18.0),
              (sw * 0.03).clamp(10.0, 12.0),
            ),
            child: Row(
              children: [
                Container(
                  width:  (sw * 0.09).clamp(32.0, 38.0),
                  height: (sw * 0.09).clamp(32.0, 38.0),
                  decoration: BoxDecoration(
                    color: _kNavy.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kNavy.withValues(alpha: 0.12)),
                  ),
                  child: Icon(Icons.trending_up_rounded,
                      color: _kNavyMid, size: (sw * 0.045).clamp(15.0, 18.0)),
                ),
                SizedBox(width: (sw * 0.025).clamp(8.0, 10.0)),
                Text(
                  'Performance Trends',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: c.primaryText,
                    fontSize: (sw * 0.038).clamp(13.5, 16.0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: c.divider),
          SizedBox(height: (sw * 0.02).clamp(6.0, 8.0)),
          ...trends.asMap().entries.map((e) {
            final isLast = e.key == trends.length - 1;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: (sw * 0.045).clamp(14.0, 18.0),
                    vertical: (sw * 0.022).clamp(7.0, 9.0),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Index pill
                      Container(
                        width:  (sw * 0.055).clamp(20.0, 24.0),
                        height: (sw * 0.055).clamp(20.0, 24.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kGreen, _kNavyMid],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          '${e.key + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: (sw * 0.024).clamp(9.0, 11.0),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(width: (sw * 0.025).clamp(8.0, 10.0)),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            color: c.primaryText,
                            fontSize: (sw * 0.032).clamp(11.5, 14.0),
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: (sw * 0.045).clamp(14.0, 18.0),
                    ),
                    child: Container(height: 0.5, color: c.divider),
                  ),
              ],
            );
          }),
          SizedBox(height: (sw * 0.02).clamp(6.0, 8.0)),
        ],
      ),
    );
  }
}

// ── GolfDNASection — top-level entry point for the Profile screen ─────────────

class GolfDNASection extends StatelessWidget {
  final GolfDNA dna;
  const GolfDNASection({super.key, required this.dna});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final sw = MediaQuery.of(context).size.width;

    final traits = [
      (label: 'Driving Power', value: dna.drivingPower, color: _kGreenLt),
      (label: 'Accuracy',      value: dna.accuracy,     color: const Color(0xFF42B0FF)),
      (label: 'Putting',       value: dna.putting,      color: _kGold),
      (label: 'Consistency',   value: dna.consistency,  color: const Color(0xFFAB87FF)),
      (label: 'Risk Level',    value: dna.riskLevel,    color: const Color(0xFFFF8A65)),
      (label: 'Stamina',       value: dna.stamina,      color: const Color(0xFF4DD0E1)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'GOLF DNA',
            style: TextStyle(
              color: c.tertiaryText,
              fontSize: (sw * 0.026).clamp(10.0, 12.0),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),

        // Hero card
        GolfDNACard(dna: dna),
        SizedBox(height: (sw * 0.035).clamp(10.0, 14.0)),

        // Trait bars card
        Container(
          decoration: ShapeDecoration(
            color: c.cardBg,
            shape: SuperellipseShape(
              borderRadius: BorderRadius.circular(40),
              side: BorderSide(color: c.cardBorder),
            ),
            shadows: c.cardShadow,
          ),
          padding: EdgeInsets.fromLTRB(
            (sw * 0.045).clamp(14.0, 18.0),
            (sw * 0.04).clamp(12.0, 16.0),
            (sw * 0.045).clamp(14.0, 18.0),
            (sw * 0.04).clamp(12.0, 16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sub-header
              Row(
                children: [
                  Container(
                    width:  (sw * 0.09).clamp(32.0, 38.0),
                    height: (sw * 0.09).clamp(32.0, 38.0),
                    decoration: BoxDecoration(
                      color: c.accentBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.accentBorder),
                    ),
                    child: Icon(Icons.bar_chart_rounded,
                        color: c.accent, size: (sw * 0.045).clamp(15.0, 18.0)),
                  ),
                  SizedBox(width: (sw * 0.025).clamp(8.0, 10.0)),
                  Text(
                    'Trait Analysis',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: c.primaryText,
                      fontSize: (sw * 0.038).clamp(13.5, 16.0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: (sw * 0.035).clamp(10.0, 14.0)),
              Container(height: 1, color: c.divider),
              SizedBox(height: (sw * 0.02).clamp(6.0, 8.0)),
              ...traits.asMap().entries.map((e) => DNATraitBar(
                    label: e.value.label,
                    value: e.value.value,
                    color: e.value.color,
                    delay: Duration(milliseconds: e.key * 80),
                  )),
            ],
          ),
        ),
        SizedBox(height: (sw * 0.035).clamp(10.0, 14.0)),

        // Trends
        DNATrendCard(trends: dna.trends),
      ],
    );
  }
}
