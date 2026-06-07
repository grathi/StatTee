"""
Physics-Informed Kalman Filter (PIKF) tracker.

Key improvements:

1. GRAVITY — After each predict step, a per-frame gravity increment is added
   to vy so the predicted arc follows a parabola, not a straight line.

2. DYNAMIC MAX_JUMP — Rejection threshold scales with current estimated speed
   (at least 350 px, or 3× current speed).  A ball moving 300 px/frame gets a
   threshold of ~900 px, so real post-impact detections are not discarded.

3. EXTENDED MISS — MAX_MISS raised to 90 frames (~3 s at 30 fps) so the
   tracker survives sky-vanishing gaps (ball lost in sky contrast drop).

4. LAUNCH VELOCITY SEEDING — The tracker measures actual pixel velocity from
   the first N good post-impact detections, then seeds the Kalman with that
   velocity so physics prediction immediately extrapolates the correct arc even
   when the ball disappears into the sky.

5. STATIONARY FILTER — Detections that barely move from the previous frame
   (< MIN_MOTION_PX) are treated as misses before impact and rejected after
   impact. This eliminates false positives from scattered range balls.
"""
from __future__ import annotations

import math
from typing import Optional
import numpy as np
from filterpy.kalman import KalmanFilter  # type: ignore


MAX_MISS        = 90     # frames of miss before abandoning track (~3 s at 30 fps)
G_PX_PER_FRAME  = 0.55   # gravity increment per frame in pixels
MIN_JUMP_PX     = 450.0  # floor for dynamic jump threshold
JUMP_SPEED_MULT = 3.0    # threshold = max(MIN_JUMP_PX, speed × this)

# Velocity seed: require at least this many good post-impact detections to
# compute launch velocity before relying on Kalman prediction only.
_SEED_FRAMES = 3
# Detections that move less than this from the previous one are filtered out
# post-impact (stationary range balls / false positives).
_MIN_MOTION_PX = 4.0


def track(
    detections: list[Optional[tuple[float, float, float]]],
    impact_frame: int = 0,
    fps: float = 30.0,
    hint_px: Optional[tuple[float, float]] = None,
) -> list[Optional[tuple[float, float]]]:
    """
    Input:  detections[i] = (cx, cy, r) or None
    Output: tracked[i]    = (cx, cy) or None

    impact_frame  — absolute frame index where ball was hit
    fps           — frames per second
    hint_px       — pixel position of ball at address (from user tap)
    """
    kf              = _make_kf()
    initialized     = False
    miss_streak     = 0
    output: list[Optional[tuple[float, float]]] = []

    # Collect the first good post-impact positions to measure launch velocity
    seed_positions: list[tuple[float, float]] = []
    velocity_seeded = False
    prev_det: Optional[tuple[float, float]] = None   # last accepted detection

    for frame_idx, det in enumerate(detections):
        post_impact = (frame_idx >= impact_frame)

        # ── Dynamic jump threshold ────────────────────────────────────────────
        if initialized:
            vx       = float(kf.x[2])
            vy       = float(kf.x[3])
            speed    = math.sqrt(vx * vx + vy * vy)
            max_jump = max(MIN_JUMP_PX, speed * JUMP_SPEED_MULT)
        else:
            max_jump = MIN_JUMP_PX

        # ── Stationary-ball filter (post-impact only) ─────────────────────────
        if det is not None and post_impact and prev_det is not None:
            cx0, cy0 = det[0], det[1]
            dx = cx0 - prev_det[0]
            dy = cy0 - prev_det[1]
            if math.sqrt(dx * dx + dy * dy) < _MIN_MOTION_PX:
                det = None   # ignore — it's a stationary range ball

        if det is not None:
            cx, cy, _ = det

            # ── Velocity-spike rejection ──────────────────────────────────────
            if initialized:
                dx = cx - float(kf.x[0])
                dy = cy - float(kf.x[1])
                if (dx * dx + dy * dy) > max_jump ** 2:
                    # Treat as a miss — keep predicting along physics arc
                    if miss_streak < MAX_MISS:
                        _predict_with_gravity(kf)
                        miss_streak += 1
                        output.append((float(kf.x[0]), float(kf.x[1])))
                    else:
                        output.append(None)
                    continue

            z = np.array([[cx], [cy]])
            if not initialized:
                kf.x[0] = cx
                kf.x[1] = cy
                initialized = True
                miss_streak = 0
            else:
                _predict_with_gravity(kf)
                kf.update(z)
                miss_streak = 0
            prev_det = (cx, cy)
            output.append((float(kf.x[0]), float(kf.x[1])))

            # ── Collect seed positions post-impact ────────────────────────────
            if post_impact and not velocity_seeded:
                seed_positions.append((cx, cy))
                if len(seed_positions) >= _SEED_FRAMES:
                    _seed_velocity(kf, seed_positions)
                    velocity_seeded = True

        else:
            # No detection this frame — predict forward along the physics arc
            if initialized and miss_streak < MAX_MISS:
                # If we have enough seed points but haven't seeded yet (e.g.
                # ball disappears before _SEED_FRAMES), seed now with what we have
                if post_impact and not velocity_seeded and len(seed_positions) >= 2:
                    _seed_velocity(kf, seed_positions)
                    velocity_seeded = True
                _predict_with_gravity(kf)
                miss_streak += 1
                output.append((float(kf.x[0]), float(kf.x[1])))
            else:
                output.append(None)

    return output


# ── Helpers ───────────────────────────────────────────────────────────────────

def _seed_velocity(kf: KalmanFilter, positions: list[tuple[float, float]]) -> None:
    """
    Compute average frame-to-frame velocity from the first few post-impact
    detections and inject it into the Kalman state.  This gives the physics
    predictor a realistic launch velocity so it can extrapolate the full arc
    even when the ball vanishes in the sky.
    """
    vxs, vys = [], []
    for i in range(1, len(positions)):
        vxs.append(positions[i][0] - positions[i - 1][0])
        vys.append(positions[i][1] - positions[i - 1][1])
    if vxs:
        kf.x[2] = float(np.mean(vxs))   # vx
        kf.x[3] = float(np.mean(vys))   # vy


def _predict_with_gravity(kf: KalmanFilter) -> None:
    """Standard Kalman predict then inject gravity into vy (and y)."""
    kf.predict()
    kf.x[3] += G_PX_PER_FRAME          # vy += g  (downward acceleration)
    kf.x[1] += 0.5 * G_PX_PER_FRAME    # y  += 0.5*g (half-step correction)


def _make_kf() -> KalmanFilter:
    kf  = KalmanFilter(dim_x=4, dim_z=2)
    dt  = 1.0
    kf.F = np.array([
        [1, 0, dt,  0],
        [0, 1,  0, dt],
        [0, 0,  1,  0],
        [0, 0,  0,  1],
    ], dtype=float)
    kf.H = np.array([
        [1, 0, 0, 0],
        [0, 1, 0, 0],
    ], dtype=float)
    kf.R *= 10     # measurement noise
    kf.P *= 100    # initial covariance
    kf.Q *= 0.1    # process noise
    return kf
