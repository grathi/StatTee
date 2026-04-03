"""
Neon trail renderer. Draws the ball path overlay onto each frame and
re-encodes to output.mp4 via ffmpeg.
"""
from __future__ import annotations

import subprocess
from pathlib import Path
import cv2
import numpy as np
from typing import Optional


# Neon green (BGR)
_NEON_OUTER = (52, 195, 123)   # #7BC344
_NEON_INNER = (78, 212, 143)   # #8FD44E
_NEON_CORE  = (68, 255, 204)   # #CCFF44


def draw_overlay(
    frames_dir: Path,
    tracked: list[Optional[tuple[float, float]]],
    out_frames_dir: Path,
) -> None:
    """Render neon trail onto each frame and write to out_frames_dir.
    Trail is built incrementally (O(n) total) rather than rebuilt each frame.
    """
    out_frames_dir.mkdir(parents=True, exist_ok=True)
    frame_paths = sorted(frames_dir.glob("*.jpg"))

    trail: list[tuple[int, int]] = []  # grows as video progresses

    for i, fp in enumerate(frame_paths):
        # Append new point before drawing so it appears on this frame
        if i < len(tracked) and tracked[i] is not None:
            trail.append((int(tracked[i][0]), int(tracked[i][1])))

        img = cv2.imread(str(fp))

        if len(trail) >= 2:
            pts = np.array(trail, dtype=np.int32)
            # Layer 1: outer glow
            cv2.polylines(img, [pts], False, _NEON_OUTER, 12,
                          lineType=cv2.LINE_AA)
            # Layer 2: inner glow
            overlay = img.copy()
            cv2.polylines(overlay, [pts], False, _NEON_INNER, 6,
                          lineType=cv2.LINE_AA)
            cv2.addWeighted(overlay, 0.7, img, 0.3, 0, img)
            # Layer 3: crisp core
            cv2.polylines(img, [pts], False, _NEON_CORE, 2,
                          lineType=cv2.LINE_AA)

        # Ball tip dot
        if trail:
            cx, cy = trail[-1]
            cv2.circle(img, (cx, cy), 5, (255, 255, 255), -1, lineType=cv2.LINE_AA)
            cv2.circle(img, (cx, cy), 3, _NEON_CORE, -1, lineType=cv2.LINE_AA)

        cv2.imwrite(str(out_frames_dir / fp.name), img)


def encode_video(
    out_frames_dir: Path,
    output_mp4: Path,
    fps: float,
) -> None:
    """Re-encode rendered frames to H.264 MP4 using ffmpeg."""
    cmd = [
        "ffmpeg", "-y",
        "-framerate", str(fps),
        "-pattern_type", "glob",
        "-i", str(out_frames_dir / "*.jpg"),
        "-c:v", "libx264",
        "-preset", "ultrafast",
        "-crf", "28",
        "-pix_fmt", "yuv420p",
        str(output_mp4),
    ]
    subprocess.run(cmd, check=True, capture_output=True)
