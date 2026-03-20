import '../models/round.dart';

class StrokesGained {
  final double offTee;
  final double approach;
  final double aroundGreen;
  final double putting;

  const StrokesGained({
    required this.offTee,
    required this.approach,
    required this.aroundGreen,
    required this.putting,
  });

  double get total => offTee + approach + aroundGreen + putting;

  static const zero = StrokesGained(
    offTee: 0,
    approach: 0,
    aroundGreen: 0,
    putting: 0,
  );
}

/// Calculates simplified Strokes Gained proxies from available hole-level data.
///
/// Since we don't track shot-by-shot distances, we use stat deviations vs
/// scratch-golfer baselines to estimate strokes gained per category.
///
/// Baselines (scratch golfer approximations):
///   - FIR%: 60%
///   - GIR%: 67%
///   - Putts/hole: 1.83
///   - Miss-GIR bogey rate: 50% (scratch makes up-and-down ~50% of the time)
class StrokesGainedService {
  // ── Scratch baselines ─────────────────────────────────────────────────────
  static const _baselineFir = 60.0;      // % fairways in regulation
  static const _baselineGir = 67.0;      // % greens in regulation
  static const _baselinePutts = 1.83;    // putts per hole
  static const _baselineMissGirBogey = 0.50; // bogey rate when missing GIR

  // Scaling factors: 1% FIR deviation ≈ 0.02 strokes per hole on average
  static const _firScale = 0.02;
  static const _girScale = 0.03;
  static const _puttScale = 1.0;       // 1 putt difference = 1 stroke gained
  static const _aroundGreenScale = 0.5; // 1% bogey rate change ≈ 0.5 strokes

  static StrokesGained calculate(List<Round> rounds) {
    if (rounds.isEmpty) return StrokesGained.zero;

    // Collect all hole scores across rounds
    final allHoles = rounds.expand((r) => r.scores).toList();
    if (allHoles.isEmpty) return StrokesGained.zero;

    // ── Off the Tee (FIR deviation) ──────────────────────────────────────
    final par45Holes = allHoles.where((h) => h.par >= 4).toList();
    final userFir = par45Holes.isEmpty
        ? _baselineFir
        : par45Holes.where((h) => h.fairwayHit).length /
              par45Holes.length *
              100;
    final offTee = (userFir - _baselineFir) * _firScale;

    // ── Approach (GIR deviation) ─────────────────────────────────────────
    final userGir =
        allHoles.isEmpty ? _baselineGir : allHoles.where((h) => h.gir).length / allHoles.length * 100;
    final approach = (userGir - _baselineGir) * _girScale;

    // ── Around the Green (scrambling on missed GIRs) ──────────────────────
    final missedGirHoles = allHoles.where((h) => !h.gir).toList();
    double aroundGreen = 0;
    if (missedGirHoles.isNotEmpty) {
      // bogey-or-better when missing GIR = scrambling success
      final scramblePct =
          missedGirHoles.where((h) => h.diff <= 1).length / missedGirHoles.length;
      aroundGreen = (scramblePct - _baselineMissGirBogey) * _aroundGreenScale;
    }

    // ── Putting ───────────────────────────────────────────────────────────
    final holesWithPutts = allHoles.where((h) => h.putts > 0).toList();
    double putting = 0;
    if (holesWithPutts.isNotEmpty) {
      final avgPutts =
          holesWithPutts.fold(0, (s, h) => s + h.putts) / holesWithPutts.length;
      putting = (_baselinePutts - avgPutts) * _puttScale;
    }

    return StrokesGained(
      offTee: double.parse(offTee.toStringAsFixed(2)),
      approach: double.parse(approach.toStringAsFixed(2)),
      aroundGreen: double.parse(aroundGreen.toStringAsFixed(2)),
      putting: double.parse(putting.toStringAsFixed(2)),
    );
  }
}
