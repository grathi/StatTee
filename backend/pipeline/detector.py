"""
Golf ball detector — YOLOv8-based with directional cone filter.

Detection strategy:
  1. YOLOv8 model (golf-ball-specific if available, COCO sports ball fallback)
     runs at imgsz=1280 — critical for small golf balls.
  2. Two spatial/directional gates applied post-impact:
     Gate A: ball must be ABOVE tee Y (golfer body / ground eliminated)
     Gate B: ball must move in the direction established by the first 2+
             post-impact detections (cone filter, 60° half-angle)

This combination fixes the "opposite direction" bug caused by TrackNet
firing on golfer arm/body motion (large signal) instead of the ball.

detect_all() returns the same (detections, impact_frame) interface as before —
processor.py / tracker.py need no changes.
"""
from __future__ import annotations

import logging
import math
import os
from pathlib import Path
from typing import Optional

import cv2
import numpy as np

logger = logging.getLogger(__name__)

# ── Model paths ───────────────────────────────────────────────────────────────
_MODEL_PATH = Path("/app/models/golfball.pt")
_FALLBACK   = "yolov8n.pt"          # COCO; class 32 = sports ball

# ── Detection settings ────────────────────────────────────────────────────────
_CONF            = 0.15    # low threshold — ball is small and partially blurred
_IMGSZ           = 1280    # must use 1280; ball vanishes at 640

# ── Directional cone filter ───────────────────────────────────────────────────
_BELOW_TEE_MARGIN = 30     # px below tee Y still accepted (slight tolerance)
_CONE_COS         = 0.50   # cos(60°) — half-angle of allowed direction cone
_DIR_LOCK_MIN_PTS = 2      # how many post-impact detections needed to lock dir

# ── Impact detection ──────────────────────────────────────────────────────────
_IMPACT_CROP_HALF = 250

# ── Singleton model ───────────────────────────────────────────────────────────
_model = None
_target_classes: Optional[list[int]] = None


def _get_model():
    global _model, _target_classes
    if _model is None:
        from ultralytics import YOLO  # lazy import to keep startup fast
        path = Path(os.environ.get("YOLO_MODEL_PATH", str(_MODEL_PATH)))
        if path.exists():
            logger.info(f"[detector] Loading YOLO model from {path}")
            _model = YOLO(str(path))
        else:
            logger.warning(
                "[detector] No golf ball model at %s — "
                "falling back to YOLOv8n COCO (sports ball class 32)", path
            )
            _model = YOLO(_FALLBACK)

        # Auto-detect which class IDs correspond to balls
        names = _model.names  # dict {id: name}
        ball_ids = [k for k, v in names.items()
                    if "golf" in v.lower() or "ball" in v.lower()]
        _target_classes = ball_ids if ball_ids else None
        logger.info(f"[detector] target classes: {_target_classes} "
                    f"({[names[c] for c in (_target_classes or [])]})")
    return _model


# ── Public API ────────────────────────────────────────────────────────────────

def find_impact_frame(
    frame_paths: list[Path],
    hint_px: Optional[tuple[float, float]],
    frame_w: int,
    frame_h: int,
) -> int:
    """
    Scan consecutive frame pairs for the largest inter-frame motion spike
    inside a crop centred on the hint (or full frame when no hint given).
    Never reports impact in the last 10% of frames.
    """
    n = len(frame_paths)
    if n < 3:
        return 0

    max_idx = max(1, int(n * 0.9))

    if hint_px is not None:
        hx, hy = int(hint_px[0]), int(hint_px[1])
        x1 = max(0, hx - _IMPACT_CROP_HALF)
        y1 = max(0, hy - _IMPACT_CROP_HALF)
        x2 = min(frame_w, hx + _IMPACT_CROP_HALF)
        y2 = min(frame_h, hy + _IMPACT_CROP_HALF)
    else:
        x1, y1, x2, y2 = 0, 0, frame_w, frame_h

    best_score = -1.0
    best_idx   = 0
    prev_gray: Optional[np.ndarray] = None

    for i in range(0, min(n, max_idx), 2):
        img = cv2.imread(str(frame_paths[i]))
        if img is None:
            prev_gray = None
            continue
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        if prev_gray is not None:
            diff  = cv2.absdiff(gray[y1:y2, x1:x2], prev_gray[y1:y2, x1:x2])
            score = float(np.mean(diff))
            if score > best_score:
                best_score = score
                best_idx   = i
        prev_gray = gray

    return best_idx


def detect_all(
    frames_dir: Path,
    ball_hint: Optional[dict] = None,
    frame_w: int = 1920,
    frame_h: int = 1080,
) -> tuple[list[Optional[tuple[float, float, float]]], int]:
    """
    Run YOLOv8 golf ball detection on every frame.

    Returns:
        detections   — list of (cx, cy, r) or None, one entry per frame
        impact_frame — absolute frame index of detected impact
    """
    frame_paths = sorted(frames_dir.glob("*.jpg"))
    if not frame_paths:
        return [], 0

    hint_px: Optional[tuple[float, float]] = None
    if ball_hint is not None:
        hint_px = (ball_hint["x"] * frame_w, ball_hint["y"] * frame_h)

    impact_frame = find_impact_frame(frame_paths, hint_px, frame_w, frame_h)
    logger.info(f"[detector] impact_frame={impact_frame} / {len(frame_paths)} frames")

    model = _get_model()

    # Direction lock state
    dir_vec: Optional[tuple[float, float]] = None   # unit vector of ball flight
    post_impact_detections: list[tuple[float, float]] = []  # used to build dir_vec

    detections: list[Optional[tuple[float, float, float]]] = []

    for i, fp in enumerate(frame_paths):
        img = cv2.imread(str(fp))
        if img is None:
            detections.append(None)
            continue

        post_impact = (i >= impact_frame)

        # Run YOLO inference
        results = model.predict(
            img,
            imgsz=_IMGSZ,
            conf=_CONF,
            classes=_target_classes,
            verbose=False,
        )
        boxes = results[0].boxes

        if boxes is None or len(boxes) == 0:
            detections.append(None)
            continue

        # Convert boxes to centroids with confidence
        candidates: list[tuple[float, float, float, float]] = []  # cx, cy, r, conf
        for box in boxes:
            x1, y1_b, x2, y2_b = box.xyxy[0].tolist()
            conf = float(box.conf[0])
            cx = (x1 + x2) / 2.0
            cy = (y1_b + y2_b) / 2.0
            r  = max(x2 - x1, y2_b - y1_b) / 2.0
            candidates.append((cx, cy, r, conf))

        # Apply directional gates post-impact
        if post_impact:
            candidates = _apply_gates(candidates, hint_px, dir_vec)

        if not candidates:
            detections.append(None)
            continue

        # Pick best candidate: highest confidence
        best = max(candidates, key=lambda c: c[3])
        cx, cy, r, _ = best
        detections.append((cx, cy, r))

        # Update direction lock from first N post-impact detections
        if post_impact and hint_px is not None:
            post_impact_detections.append((cx, cy))
            if len(post_impact_detections) >= _DIR_LOCK_MIN_PTS and dir_vec is None:
                # Direction: from tee toward first ball position
                fx, fy = post_impact_detections[0]
                dx = fx - hint_px[0]
                dy = fy - hint_px[1]
                dist = math.sqrt(dx * dx + dy * dy)
                if dist > 1.0:
                    dir_vec = (dx / dist, dy / dist)
                    logger.info(f"[detector] direction locked: {dir_vec}")

    detected = sum(1 for d in detections if d is not None)
    logger.info(f"[detector] {detected} / {len(frame_paths)} frames with detections")
    return detections, impact_frame


# ── Directional gate ──────────────────────────────────────────────────────────

def _apply_gates(
    candidates: list[tuple[float, float, float, float]],
    hint_px: Optional[tuple[float, float]],
    dir_vec: Optional[tuple[float, float]],
) -> list[tuple[float, float, float, float]]:
    """
    Apply two post-impact spatial filters:
      Gate A — above-tee: reject candidates below tee Y + margin
      Gate B — cone: reject candidates outside established flight direction
    """
    result = []
    for (cx, cy, r, conf) in candidates:
        # Gate A: spatial above-tee
        if hint_px is not None:
            if cy > hint_px[1] + _BELOW_TEE_MARGIN:
                continue  # below tee = golfer body / ground

        # Gate B: direction cone (only once direction is locked)
        if hint_px is not None and dir_vec is not None:
            dx = cx - hint_px[0]
            dy = cy - hint_px[1]
            dist = math.sqrt(dx * dx + dy * dy)
            if dist > 5.0:  # ignore detections very close to tee
                nx, ny = dx / dist, dy / dist
                dot = nx * dir_vec[0] + ny * dir_vec[1]
                if dot < _CONE_COS:
                    continue  # outside 60° cone = wrong direction

        result.append((cx, cy, r, conf))
    return result
