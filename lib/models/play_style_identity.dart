import 'package:flutter/material.dart';

enum PlayStyleType {
  aggressiveStriker,
  strategicPlayer,
  consistentPlayer,
  shortGameMaster,
  safePlayer,
  weekendGolfer,
}

class PlayStyleIdentity {
  final PlayStyleType type;
  final String title;
  final String description;
  final List<String> traits;
  final int confidenceScore; // 0–100
  final DateTime lastUpdated;

  const PlayStyleIdentity({
    required this.type,
    required this.title,
    required this.description,
    required this.traits,
    required this.confidenceScore,
    required this.lastUpdated,
  });

  // Visual config per type ──────────────────────────────────────────────────

  IconData get icon {
    switch (type) {
      case PlayStyleType.aggressiveStriker:  return Icons.bolt_rounded;
      case PlayStyleType.strategicPlayer:    return Icons.psychology_rounded;
      case PlayStyleType.consistentPlayer:   return Icons.show_chart_rounded;
      case PlayStyleType.shortGameMaster:    return Icons.sports_golf_rounded;
      case PlayStyleType.safePlayer:         return Icons.shield_rounded;
      case PlayStyleType.weekendGolfer:      return Icons.wb_sunny_rounded;
    }
  }

  List<Color> get gradient {
    switch (type) {
      case PlayStyleType.aggressiveStriker:
        return [const Color(0xFFFF6B35), const Color(0xFFC0392B)];
      case PlayStyleType.strategicPlayer:
        return [const Color(0xFF2980B9), const Color(0xFF1A1A2E)];
      case PlayStyleType.consistentPlayer:
        return [const Color(0xFF27AE60), const Color(0xFF145A32)];
      case PlayStyleType.shortGameMaster:
        return [const Color(0xFF8E44AD), const Color(0xFF2C2C54)];
      case PlayStyleType.safePlayer:
        return [const Color(0xFF16A085), const Color(0xFF0C3547)];
      case PlayStyleType.weekendGolfer:
        return [const Color(0xFFF39C12), const Color(0xFFB7770D)];
    }
  }

  Color get primaryColor => gradient.first;
  Color get glowColor    => gradient.first.withValues(alpha: 0.35);
}
