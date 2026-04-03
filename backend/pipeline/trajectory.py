"""
Trajectory smoothing and shot metric estimation.
Converts tracked pixel points → smoothed BallPoints normalized to 0-1000.
"""
from __future__ import annotations

import math
import numpy as np
from scipy.interpolate import UnivariateSpline  # type: ignore
from typing import Optional


_MIN_POINTS = 5  # minimum tracked points needed for a valid trajectory


def smooth(
    tracked: list[Optional[tuple[float, float]]],
    fps: float,
    frame_width: int,
    frame_height: int,
) -> tuple[list[dict], dict]:
    """
    Returns:
        ball_path  — list of {t, x, y} dicts (t in ms, x/y 0-1000)
        shot_data  — {carry_yards, max_height_yards, launch_angle}
    """
    pts: list[tuple[float, float, float]] = []
    for i, p in enumerate(tracked):
        if p is not None:
            t_ms = i / fps * 1000
            pts.append((t_ms, p[0], p[1]))

    if len(pts) < _MIN_POINTS:
        return [], {"carry_yards": 0, "max_height_yards": 0, "launch_angle": 0}

    ts = np.array([p[0] for p in pts])
    xs = np.array([p[1] for p in pts])
    ys = np.array([p[2] for p in pts])

    k = min(3, len(pts) - 1)
    sp_x = UnivariateSpline(ts, xs, k=k, s=len(pts))
    sp_y = UnivariateSpline(ts, ys, k=k, s=len(pts))

    # Sample 25 evenly-spaced points along the trajectory
    t_eval = np.linspace(ts[0], ts[-1], 25)
    sx = sp_x(t_eval)
    sy = sp_y(t_eval)

    # Normalize to 0-1000
    ball_path = [
        {
            "t": int(round(float(t))),
            "x": int(round(float(x) / frame_width  * 1000)),
            "y": int(round(float(y) / frame_height * 1000)),
        }
        for t, x, y in zip(t_eval, sx, sy)
    ]

    # Shot metrics (rough estimates from pixel trajectory)
    horiz_px = abs(float(sx[-1]) - float(sx[0]))
    carry_yards = round(horiz_px / frame_width * 250, 1)

    height_px = max(0.0, float(ys[0]) - float(np.min(sy)))
    max_height_yards = round(height_px / frame_height * 40, 1)

    dx0 = float(sp_x.derivative()(ts[0]))
    dy0 = float(sp_y.derivative()(ts[0]))
    launch_angle = round(math.degrees(math.atan2(-dy0, abs(dx0))), 1)

    shot_data = {
        "carry_yards": carry_yards,
        "max_height_yards": max_height_yards,
        "launch_angle": launch_angle,
    }
    return ball_path, shot_data
