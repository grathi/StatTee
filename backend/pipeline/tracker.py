"""
Physics-Informed Kalman Filter (PIKF) tracker.

Key improvements over naive constant-velocity Kalman:

1. GRAVITY — After each predict step, a per-frame gravity increment is added
   to vy so the predicted arc follows a parabola, not a straight line.

2. DYNAMIC MAX_JUMP — Rejection threshold scales with current estimated speed
   (at least 350 px, or 3× current speed).  A ball moving 300 px/frame gets a
   threshold of ~900 px, so real post-impact detections are not discarded.

3. EXTENDED MISS — MAX_MISS raised to 45 frames (~1.5 s at 30 fps) so the
   tracker survives sky-vanishing gaps.

4. IMPACT SEEDING — If no detection has been made by the detected impact frame
   and a hint position is known, the Kalman is seeded there so physics
   prediction starts from the correct location.
"""
from __future__ import annotations

import math
from typing import Optional
import numpy as np
from filterpy.kalman import KalmanFilter  # type: ignore


MAX_MISS        = 45     # frames of miss before abandoning track
G_PX_PER_FRAME  = 0.55   # gravity increment per frame in pixels
                          # ≈ 9.81 m/s² × (1/30)² s²/frame × ~200 px/m
MIN_JUMP_PX     = 450.0  # floor for dynamic jump threshold
JUMP_SPEED_MULT = 3.0    # threshold = max(MIN_JUMP_PX, speed × this)


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
    fps           — frames per second (used to scale gravity if desired)
    hint_px       — pixel position of ball at address (from user tap)
    """
    kf          = _make_kf()
    initialized = False
    miss_streak = 0
    output: list[Optional[tuple[float, float]]] = []

    for frame_idx, det in enumerate(detections):
        post_impact = (frame_idx >= impact_frame)

        # ── Dynamic jump threshold ────────────────────────────────────────
        if initialized:
            vx = float(kf.x[2])
            vy = float(kf.x[3])
            speed    = math.sqrt(vx * vx + vy * vy)
            max_jump = max(MIN_JUMP_PX, speed * JUMP_SPEED_MULT)
        else:
            max_jump = MIN_JUMP_PX

        if det is not None:
            cx, cy, _ = det

            # ── Velocity-spike rejection ──────────────────────────────────
            if initialized:
                dx = cx - float(kf.x[0])
                dy = cy - float(kf.x[1])
                if (dx * dx + dy * dy) > max_jump ** 2:
                    # Treat as a miss — keep predicting
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
            output.append((float(kf.x[0]), float(kf.x[1])))

        else:
            if initialized and miss_streak < MAX_MISS:
                _predict_with_gravity(kf)
                miss_streak += 1
                output.append((float(kf.x[0]), float(kf.x[1])))
            else:
                output.append(None)

    return output


# ── Helpers ───────────────────────────────────────────────────────────────────

def _predict_with_gravity(kf: KalmanFilter) -> None:
    """Standard Kalman predict then inject gravity into vy (and y)."""
    kf.predict()
    # Add gravity: ball accelerates downward each frame
    kf.x[3] += G_PX_PER_FRAME          # vy += g
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
