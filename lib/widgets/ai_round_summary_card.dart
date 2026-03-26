import 'package:flutter/material.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import '../models/round_summary_ai.dart';

class AIRoundSummaryCard extends StatelessWidget {
  final RoundSummaryAI? data;
  final bool isLoading;

  const AIRoundSummaryCard({super.key, this.data, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final body = (sw * 0.036).clamp(13.0, 16.0);
    final label = (sw * 0.030).clamp(11.0, 13.0);

    return Container(
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A08), Color(0xFF3D6E14), Color(0xFF4E8A18)],
          stops: [0.0, 0.55, 1.0],
        ),
        shape: SuperellipseShape(borderRadius: BorderRadius.circular(48)),
        shadows: const [
          BoxShadow(
            color: Color(0x3C5A9E1F),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all((sw * 0.055).clamp(18.0, 24.0)),
      child: isLoading || data == null ? _buildLoading(body, label) : _buildContent(data!, body, label),
    );
  }

  Widget _buildLoading(double body, double label) {
    return Column(
      children: [
        Row(children: [
          const Text('✨', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text('AI Round Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: label,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              )),
          const Spacer(),
          _GeminiPill(),
        ]),
        const SizedBox(height: 20),
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Text('Analyzing your round…',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: label,
            )),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildContent(RoundSummaryAI d, double body, double label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(children: [
          const Text('✨', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text('AI Round Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: label,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              )),
          const Spacer(),
          _GeminiPill(),
        ]),
        const SizedBox(height: 14),

        // Divider
        Container(height: 0.5, color: Colors.white.withValues(alpha: 0.2)),
        const SizedBox(height: 14),

        // Headline + calorie badge row
        if (d.headline.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(d.headline,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.white,
                      fontSize: (body * 1.1).clamp(14.0, 18.0),
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    )),
              ),
              if (d.calories != null) ...[
                const SizedBox(width: 10),
                _CalorieBadge(calories: d.calories!, label: label),
              ],
            ],
          ),
        if (d.headline.isNotEmpty) const SizedBox(height: 8),

        // Summary
        if (d.summary.isNotEmpty)
          Text(d.summary,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: body,
                height: 1.5,
              )),
        const SizedBox(height: 16),

        // Divider
        Container(height: 0.5, color: Colors.white.withValues(alpha: 0.2)),
        const SizedBox(height: 14),

        // Strength + Weakness chips row
        Row(children: [
          Expanded(child: _chip('💪', 'Strength', d.strength, label)),
          const SizedBox(width: 8),
          Expanded(child: _chip('⚠️', 'Weakness', d.weakness, label)),
        ]),
        const SizedBox(height: 8),

        // Focus area full width
        _chip('🎯', 'Focus Area', d.focusArea, label, fullWidth: true),
      ],
    );
  }

  Widget _chip(String emoji, String title, String text, double label,
      {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: ShapeDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: label * 0.88,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                )),
          ]),
          const SizedBox(height: 4),
          Text(text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.90),
                fontSize: label,
                height: 1.4,
              )),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Calorie badge — top-right of headline row
// ---------------------------------------------------------------------------
class _CalorieBadge extends StatelessWidget {
  final int calories;
  final double label;
  const _CalorieBadge({required this.calories, required this.label});

  @override
  Widget build(BuildContext context) {
    final formatted = _format(calories);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: ShapeDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(40),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text('$formatted kcal',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.90),
                fontSize: label * 0.92,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  static String _format(int n) {
    if (n >= 1000) {
      final k = (n / 1000).toStringAsFixed(1);
      return '${k}k';
    }
    return '$n';
  }
}

class _GeminiPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: ShapeDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: SuperellipseShape(
          borderRadius: BorderRadius.circular(40),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        ),
      ),
      child: const Text('Gemini',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          )),
    );
  }
}
