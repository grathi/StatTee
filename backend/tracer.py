"""
Golf Shot Tracer — standalone CLI script.

Runs the full ball-detection → tracking → smoothing → neon-overlay pipeline
on a local .mp4 file without any Firebase / Cloud Run dependency.

Usage:
    python tracer.py --input swing.mp4 --output traced.mp4
    python tracer.py --input swing.mp4 --output traced.mp4 --model golfball.pt
    python tracer.py --input swing.mp4 --output traced.mp4 --fps 60

Pipeline stages:
    1. Transcode  — convert any input codec (HEVC, Dolby Vision, HDR) to H.264
    2. Extract    — dump frames to JPEG files, capped at --fps
    3. Detect     — YOLOv8 finds the golf ball in every frame
    4. Track      — physics-informed Kalman filter smooths the coordinate stream
    5. Smooth     — UnivariateSpline fits a clean arc through tracked points
    6. Render     — 3-layer neon trail is drawn onto each frame
    7. Encode     — frames are re-assembled into a compressed H.264 .mp4
"""
from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import cv2


# ---------------------------------------------------------------------------
# Helpers — frame extraction and transcoding
# (Copied from processor.py so this script has zero Firebase imports)
# ---------------------------------------------------------------------------

def _transcode(src: Path, dst: Path) -> None:
    """
    Re-encode any input video to plain H.264 / BT.709.

    Handles iPhone Dolby Vision, HEVC, and HDR footage that OpenCV cannot
    decode reliably on Linux.  Output is visually lossless (CRF 18) and
    colour-correct for inference.
    """
    print("[1/7] Transcoding to H.264 …")
    subprocess.run(
        [
            "ffmpeg", "-y", "-i", str(src),
            "-c:v", "libx264", "-preset", "fast", "-crf", "18",
            # Strip HDR → SDR / BT.709 so colours are stable for detection
            "-vf", "scale=in_color_matrix=bt2020:out_color_matrix=bt709",
            "-color_primaries", "bt709",
            "-color_trc",       "bt709",
            "-colorspace",      "bt709",
            "-c:a", "aac", "-b:a", "128k",
            # Move moov atom to front — required for streaming to mobile client
            "-movflags", "+faststart",
            str(dst),
        ],
        check=True,
        capture_output=True,
    )


def _extract_frames(input_mp4: Path, frames_dir: Path, fps_cap: float) -> tuple[float, int, int]:
    """
    Extract individual JPEG frames from the video.

    Frames are capped at fps_cap (default 30).  Higher frame rates increase
    detection accuracy but also increase processing time proportionally.

    Returns: (effective_fps, frame_width, frame_height)
    """
    print("[2/7] Extracting frames …")
    frames_dir.mkdir(parents=True, exist_ok=True)

    cap = cv2.VideoCapture(str(input_mp4))
    src_fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    frame_w = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    frame_h = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    cap.release()

    effective_fps = min(src_fps, fps_cap)

    # Use ffmpeg's fps filter rather than manual frame skipping — it handles
    # variable-frame-rate (VFR) iPhone videos correctly.
    subprocess.run(
        [
            "ffmpeg", "-y", "-i", str(input_mp4),
            "-vf", f"fps={effective_fps}",
            "-q:v", "4",          # JPEG quality 4 — good balance of size vs clarity
            str(frames_dir / "%06d.jpg"),
        ],
        check=True,
        capture_output=True,
    )
    return effective_fps, frame_w, frame_h


# ---------------------------------------------------------------------------
# Main pipeline
# ---------------------------------------------------------------------------

def _run(input_path: Path, output_path: Path, model_path: str | None, fps_cap: float) -> None:
    """Execute all 7 pipeline stages inside a temporary working directory."""

    # Set YOLO_MODEL_PATH *before* importing detector so its singleton loader
    # picks up the custom weights without any code changes.
    if model_path:
        os.environ["YOLO_MODEL_PATH"] = model_path

    # Lazy imports — keeps startup fast and lets the env var take effect first.
    from pipeline import detector, tracker, trajectory, renderer  # noqa: E402

    workdir = Path(tempfile.mkdtemp(prefix="golf_tracer_"))
    try:
        input_h264  = workdir / "input.mp4"
        frames_dir  = workdir / "frames"
        out_frames  = workdir / "out_frames"

        # ── Stage 1: Transcode ────────────────────────────────────────────────
        _transcode(input_path, input_h264)

        # ── Stage 2: Extract frames ───────────────────────────────────────────
        fps, frame_w, frame_h = _extract_frames(input_h264, frames_dir, fps_cap)
        frame_count = len(list(frames_dir.glob("*.jpg")))
        print(f"         {frame_count} frames @ {fps:.1f} fps  ({frame_w}×{frame_h})")

        # ── Stage 3: Detect ───────────────────────────────────────────────────
        # detect_all() runs YOLOv8 on every frame at imgsz=1280.
        # Returns a list of (cx, cy, radius) | None per frame, plus the
        # frame index where the ball was struck (impact_frame).
        print("[3/7] Detecting golf ball …")
        detections, impact_frame = detector.detect_all(
            frames_dir,
            ball_hint=None,   # no user-provided tap hint in CLI mode
            frame_w=frame_w,
            frame_h=frame_h,
        )
        detected_count = sum(1 for d in detections if d is not None)
        print(f"         {detected_count} / {len(detections)} frames with detections  "
              f"(impact @ frame {impact_frame})")

        # ── Stage 4: Track ────────────────────────────────────────────────────
        # The physics-informed Kalman filter:
        #   • predicts ball position under gravity when YOLO misses a frame
        #   • rejects detections that are implausibly far from the predicted arc
        #   • survives up to 45 consecutive missed frames (sky gaps)
        print("[4/7] Tracking with Kalman filter …")
        tracked = tracker.track(
            detections,
            impact_frame=impact_frame,
            fps=fps,
            hint_px=None,
        )
        tracked_count = sum(1 for t in tracked if t is not None)
        print(f"         {tracked_count} / {len(tracked)} frames tracked")

        # ── Stage 5: Smooth & metrics ──────────────────────────────────────────
        # UnivariateSpline fits a smooth arc through the tracked coordinates.
        # Also computes rough carry distance, max height, and launch angle.
        print("[5/7] Smoothing trajectory …")
        ball_path, shot_data = trajectory.smooth(tracked, fps, frame_w, frame_h)
        if ball_path:
            print(f"         carry ≈ {shot_data['carry_yards']} yds  |  "
                  f"max height ≈ {shot_data['max_height_yards']} yds  |  "
                  f"launch angle ≈ {shot_data['launch_angle']}°")
        else:
            print("         not enough points to compute shot metrics")

        # ── Stage 6: Render overlay ────────────────────────────────────────────
        # Draws a 3-layer neon trail (outer glow / inner glow / crisp core)
        # onto each frame, growing the trail incrementally as the video plays.
        print("[6/7] Rendering neon trail …")
        renderer.draw_overlay(frames_dir, tracked, out_frames)

        # ── Stage 7: Encode output video ──────────────────────────────────────
        # Re-assembles the rendered frames into a compressed H.264 .mp4
        # (CRF 28, yuv420p) ready to stream to a mobile client.
        print("[7/7] Encoding output video …")
        renderer.encode_video(out_frames, output_path, fps)
        print(f"\n✓ Done — output saved to: {output_path}")
        print(f"  Shot data: {shot_data}")

    finally:
        # Always clean up temp files regardless of success or failure.
        shutil.rmtree(workdir, ignore_errors=True)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Golf Shot Tracer — overlay a neon ball trajectory on a swing video.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--input", "-i",
        required=True,
        help="Path to input .mp4 video file",
    )
    parser.add_argument(
        "--output", "-o",
        default="output.mp4",
        help="Path for the rendered output .mp4 (default: output.mp4)",
    )
    parser.add_argument(
        "--model", "-m",
        default=None,
        help="Path to custom YOLO weights file (e.g. golfball.pt). "
             "Falls back to YOLOv8n COCO sports-ball class when omitted.",
    )
    parser.add_argument(
        "--fps",
        type=float,
        default=30.0,
        help="Frame-rate cap for frame extraction (default: 30). "
             "Higher values improve detection but increase processing time.",
    )
    args = parser.parse_args()

    input_path  = Path(args.input).resolve()
    output_path = Path(args.output).resolve()

    if not input_path.exists():
        print(f"Error: input file not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    if not shutil.which("ffmpeg"):
        print("Error: ffmpeg not found in PATH. Install it with: brew install ffmpeg",
              file=sys.stderr)
        sys.exit(1)

    print(f"Golf Shot Tracer")
    print(f"  input  : {input_path}")
    print(f"  output : {output_path}")
    print(f"  model  : {args.model or 'YOLOv8n COCO (fallback)'}")
    print(f"  fps cap: {args.fps}")
    print()

    _run(input_path, output_path, args.model, args.fps)


if __name__ == "__main__":
    main()
