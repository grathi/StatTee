import 'package:flutter/material.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/play_style_identity.dart';
import '../theme/app_theme.dart';

// ── PlayStyleCard — hero card for the Profile screen ─────────────────────────

class PlayStyleCard extends StatefulWidget {
  final PlayStyleIdentity identity;
  const PlayStyleCard({super.key, required this.identity});

  @override
  State<PlayStyleCard> createState() => _PlayStyleCardState();
}

class _PlayStyleCardState extends State<PlayStyleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>    _fade;
  late final Animation<Offset>    _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Slight delay so it appears after the profile card settles
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _CardContent(identity: widget.identity),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final PlayStyleIdentity identity;
  const _CardContent({required this.identity});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final id = identity;

    return Container(
      width: double.infinity,
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: id.gradient,
        ),
        shape: SuperellipseShape(borderRadius: BorderRadius.circular(48)),
        shadows: [
          BoxShadow(
            color:      id.glowColor,
            blurRadius: 28,
            offset:     const Offset(0, 10),
          ),
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative circles
          Positioned(
            top:   -40,
            right: -30,
            child: Container(
              width:  160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left:   -20,
            child: Container(
              width:  100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all((sw * 0.055).clamp(16.0, 22.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Row 1: label + confidence badge ───────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon badge
                    Container(
                      width:  (sw * 0.12).clamp(42.0, 50.0),
                      height: (sw * 0.12).clamp(42.0, 50.0),
                      decoration: BoxDecoration(
                        color:  Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Icon(id.icon, color: Colors.white,
                          size: (sw * 0.06).clamp(20.0, 24.0)),
                    ),
                    SizedBox(width: (sw * 0.035).clamp(10.0, 14.0)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PLAY STYLE',
                            style: TextStyle(
                              color:          Colors.white.withValues(alpha: 0.60),
                              fontSize:       (sw * 0.025).clamp(9.5, 11.5),
                              fontWeight:     FontWeight.w700,
                              letterSpacing:  1.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            id.title,
                            style: TextStyle(
                              fontFamily:  'Nunito',
                              color:       Colors.white,
                              fontSize:    (sw * 0.056).clamp(20.0, 24.0),
                              fontWeight:  FontWeight.w800,
                              height:      1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Confidence pill
                    _ConfidencePill(score: id.confidenceScore),
                  ],
                ),

                SizedBox(height: (sw * 0.04).clamp(12.0, 16.0)),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
                SizedBox(height: (sw * 0.035).clamp(10.0, 14.0)),

                // ── Description ────────────────────────────────────────────
                Text(
                  id.description,
                  style: TextStyle(
                    color:      Colors.white.withValues(alpha: 0.82),
                    fontSize:   (sw * 0.032).clamp(12.0, 14.0),
                    height:     1.55,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                SizedBox(height: (sw * 0.04).clamp(12.0, 16.0)),

                // ── Trait chips ────────────────────────────────────────────
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: id.traits
                      .map((t) => _TraitChip(label: t, sw: sw))
                      .toList(),
                ),

                SizedBox(height: (sw * 0.035).clamp(10.0, 14.0)),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.10)),
                SizedBox(height: (sw * 0.025).clamp(8.0, 10.0)),

                // ── Footer: last updated ───────────────────────────────────
                Row(
                  children: [
                    Icon(
                      Icons.update_rounded,
                      color: Colors.white.withValues(alpha: 0.45),
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Updated ${_formatDate(id.lastUpdated)}',
                      style: TextStyle(
                        color:    Colors.white.withValues(alpha: 0.45),
                        fontSize: (sw * 0.025).clamp(9.5, 11.0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final local = d.toLocal();
    final now   = DateTime.now();
    final nowDate  = DateTime(now.year, now.month, now.day);
    final thatDate = DateTime(local.year, local.month, local.day);
    final diff = nowDate.difference(thatDate).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    if (diff < 7)  return '${diff}d ago';
    return '${local.day}/${local.month}/${local.year}';
  }
}

class _ConfidencePill extends StatelessWidget {
  final int score;
  const _ConfidencePill({required this.score});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (sw * 0.025).clamp(8.0, 10.0),
        vertical: (sw * 0.012).clamp(4.0, 5.0),
      ),
      decoration: BoxDecoration(
        color:  Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: Colors.white, size: 11),
          const SizedBox(width: 4),
          Text(
            '$score%',
            style: TextStyle(
              color:      Colors.white,
              fontSize:   (sw * 0.026).clamp(9.5, 11.0),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TraitChip extends StatelessWidget {
  final String label;
  final double sw;
  const _TraitChip({required this.label, required this.sw});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (sw * 0.027).clamp(9.0, 11.0),
        vertical: (sw * 0.012).clamp(4.0, 5.0),
      ),
      decoration: BoxDecoration(
        color:  Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color:      Colors.white.withValues(alpha: 0.90),
          fontSize:   (sw * 0.028).clamp(10.0, 12.0),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── IdentityChip — compact version for use on Home screen ────────────────────

class IdentityChip extends StatelessWidget {
  final PlayStyleIdentity identity;
  final VoidCallback? onTap;
  const IdentityChip({super.key, required this.identity, this.onTap});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final id = identity;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: (sw * 0.03).clamp(10.0, 12.0),
          vertical: (sw * 0.017).clamp(6.0, 7.0),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              id.gradient.first.withValues(alpha: 0.15),
              id.gradient.last.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: id.primaryColor.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(id.icon, color: id.primaryColor, size: 14),
            const SizedBox(width: 6),
            Text(
              id.title,
              style: TextStyle(
                color:      id.primaryColor,
                fontSize:   (sw * 0.029).clamp(10.5, 12.5),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PlayStyleSection — wrapper with section header ───────────────────────────

class PlayStyleSection extends StatelessWidget {
  final PlayStyleIdentity identity;
  const PlayStyleSection({super.key, required this.identity});

  @override
  Widget build(BuildContext context) {
    final c  = AppColors.of(context);
    final sw = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: (sw * 0.01).clamp(3.0, 4.0),
            bottom: (sw * 0.03).clamp(10.0, 12.0),
          ),
          child: Row(
            children: [
              Text(
                'PLAY STYLE',
                style: TextStyle(
                  color:         c.tertiaryText,
                  fontSize:      (sw * 0.026).clamp(10.0, 12.0),
                  fontWeight:    FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: (sw * 0.02).clamp(6.0, 8.0),
                  vertical: (sw * 0.005).clamp(1.5, 2.0),
                ),
                decoration: BoxDecoration(
                  color:  identity.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'AI Powered',
                  style: TextStyle(
                    color:      identity.primaryColor,
                    fontSize:   (sw * 0.022).clamp(8.5, 10.0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        PlayStyleCard(identity: identity),
      ],
    );
  }
}
