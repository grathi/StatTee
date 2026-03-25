// ---------------------------------------------------------------------------
// CalorieCalculator — local estimate, no external API
// ---------------------------------------------------------------------------
class CalorieCalculator {
  /// Returns estimated kcal burned during a round.
  ///
  /// [holesPlayed]      9 or 18
  /// [carriedBag]       walking with bag on shoulder/cart
  /// [usedCart]         riding a golf cart
  /// [durationMinutes]  actual round duration (0 = unknown, uses hole-based default)
  /// [steps]            pedometer steps if available; overrides distance model
  static int calculate({
    required int holesPlayed,
    required bool carriedBag,
    required bool usedCart,
    int durationMinutes = 0,
    int? steps,
  }) {
    // --- Step-based path (most accurate when available) ---
    if (steps != null && steps > 0) {
      double cal = steps * 0.04;
      if (carriedBag) cal *= 1.15;
      if (usedCart)   cal *= 0.60;
      return cal.round();
    }

    // --- Distance-based estimate ---
    // Base: walking 18 holes ≈ 1350 kcal midpoint; 9 holes ≈ 700 kcal midpoint
    double base = holesPlayed >= 18 ? 1350.0 : 700.0;

    // Cart reduces effort significantly
    if (usedCart) base *= 0.60;

    // Carrying the bag adds weight / effort
    if (carriedBag && !usedCart) base *= 1.15;

    // Duration adjustment (only meaningful for walking rounds)
    if (!usedCart && durationMinutes > 240) base *= 1.10;

    return base.round();
  }
}
